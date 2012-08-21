#!/usr/bin/ruby
ENCKEY = "xxxxxxx"
MYSQL_USER = "root"
MYSQL_PWD = '"secure password"' #change me
SSH_KEY ="/root/.ssh/backup.key" #change me
$hosts =[]
$hosts[0] ="me@myhost.com" #change me
$hosts[1] ="me@myhost2.com" #change me

DATE = Time.now.strftime("%Y-%m-%d-%H%M")
DATE2 = Time.now.strftime("%Y-%m-%d")
WORK_DIR = "/backup"
HOSTNAME = `hostname`.strip
REMOTE_DIR = "/home/me/backup/#{DATE2}" #change me

#cleaning
def cleaning
  `rm -rf #{WORK_DIR}`
  `mkdir -p #{WORK_DIR}`
end

def szip dst, org, rm_org = false
  puts "Zipping #{org} -> #{dst}, delete = #{rm_org} ..."
  `7za a -mhe=on -p#{ENCKEY} #{dst} #{org}`
  `rm #{org}` if rm_org
end

def backup_mysql db
  fn = "#{WORK_DIR}/#{DATE}_#{db}.sql.txt"
  zfn = fn + ".7z"
  `mysqldump -u #{MYSQL_USER} -p#{MYSQL_PWD} #{db} > #{fn}`
  szip zfn, fn, true
end

def backup_mongo db, where=WORK_DIR
  temp_dir = where +"/mongo_temp"
  `mkdir -p #{temp_dir}`
  `mongodump --db #{db} --out=#{temp_dir}`
  szip "#{WORK_DIR}/#{DATE}_#{db}_mongodump.7z", temp_dir
  `rm -rf #{temp_dir}`
end

def make_hash
  `md5sum #{WORK_DIR}/* > #{WORK_DIR}/#{DATE}_#{HOSTNAME}_md5s.txt`
end

def send_to_remote
  puts "sending..."
  $hosts.each do |host|
    puts "processing #{host}"
    `ssh -i #{SSH_KEY} #{host} mkdir -p #{REMOTE_DIR}`
    puts "copying data to #{host}"
    `scp -i #{SSH_KEY} -r #{WORK_DIR}/* #{host}:#{REMOTE_DIR}`
  end
end

cleaning
szip "/backup/#{DATE}_githome.7z", "/home/git"
szip "/backup/#{DATE}_gitlabwww.7z", "/www"
backup_mysql "gitlabhq_production"
make_hash
send_to_remote
cleaning

