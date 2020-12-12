#!/usr/bin/ruby

require "mysql2"

print <<EOF
  Kissu-Vi cite table rebuilder
  Written by Verniy 2020-12-12

  Program reads through the table boards and posts_%s to add existing citation
  links to kissu's cites table
EOF

# db = "vichan"
# user = "v"
# pass = "--"

puts "Enter Database"
db = gets.chomp
puts "Enter User"
user = gets.chomp
puts "Enter Password"
pass = gets.chomp

# connect to db
conn = Mysql2::Client.new(:host => "127.0.0.1", :username => user, :password => pass, :database => db)
# Retrieve boards
board_arr = conn.query("SELECT uri FROM boards");
puts board_arr.count
posts_query = Array.new(board_arr.count)
board_arr.each_with_index do |board_uri, index|
  posts_query[index] = sprintf("SELECT body, id, thread,'%s' as board FROM posts_%s", board_uri["uri"], board_uri["uri"])
end
# union get all from posts_board
all_posts = conn.query( posts_query.join (" UNION ALL ") )
#search body for HTML tags with <a>
all_posts.each do |post_entry|

  #Read a cite's current post, target post, current board and target board
  capture = post_entry["body"].scan(/<a.*? href=\"\/([a-z]+)\/res\/([0-9]+)#([0-9]+)\">/) do |target_board, target_host, target|
    puts post_entry["board"] + " " +  (post_entry["thread"] ? post_entry["thread"] : post_entry["id"]).to_s  + " " + post_entry["id"].to_s + " " + target_board + " " + target_host + " " + target
    #Insert given into cites table
    insert = conn.prepare("INSERT INTO CITES(board, post, host, target_board, target, target_host) VALUES (?,?,?, ?,?,?)")
    res = insert.execute(post_entry["board"] , post_entry["id"], (post_entry["thread"] ? post_entry["thread"] : post_entry["id"]), target_board , target, target_host)
    if res != nil
      abort("Insert error")
    end
  end
end
