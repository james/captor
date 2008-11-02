#!/usr/bin/env ruby
require 'pcaplet'
require './lastfm'

# create a sniffer that grabs the first 1500 bytes of each packet
$network = Pcaplet.new('-s 1500')

# create a filter that uses our query string and the sniffer we just made
# ip = `dig +short clarus.shazamid.com`
# $filter = Pcap::Filter.new('tcp and dst port 80', $network.capture)
# $network.add_filter($filter)

for p in $network
  # if $filter =~ p
    if p && p.respond_to?(:tcp_data) && p.tcp_data && (title = p.tcp_data.match(/.+<ttitle>(.+?)<\/ttitle>.+/)) && (artist = p.tcp_data.match(/.+<tartist id=".+">(.+?)<\/tartist>.+/))
      if title && artist
        print artist[1]
        print title[1]
        submit(artist[1], title[1])
      end
    end
  # end
end