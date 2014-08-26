#!/usr/bin/env coffee

cli = require 'cli'
request = require 'request'
line = require './line'

read = (ym, bus, callback) ->
  if !/[0-9]{4}[0-1][0-9]/.test(ym) || !/[0-9]{3}/.test(bus)
    return callback error_msg

  if !line[bus]
    return callback "Invalid bus number."

  seq = line[bus]

  info_url = "http://skhappyexpress.com/ebussk/web/viewEbusLine.json"
  info_url += "?line_seq=#{seq}"

  request.get info_url, (err, resp, body) ->
    try
      info = JSON.parse(body).statusInfo
    catch e
      return callback "skhappyexpress.com Server Error"

    seat_url = "http://skhappyexpress.com/ebussk/web/listSeatByType.json"
    seat_url += "?seat_tp_cd=#{info.seat_tp_cd}"
    seat_url += "&yyyymm=#{ym}"
    seat_url += "&line_seq=#{seq}"
    seat_url += "&seat_cnt=#{info.seat_cnt}"

    request.get seat_url, (err, resp, body) ->
      try
        seat_data = JSON.parse(body).statusInfo
      catch e
        return callback "skhappyexpress.com Server Error"

      if callback
        callback null, {
          seat: seat_data
          count: info.seat_cnt
        }

render = (data, seat_cnt) ->
  seats = new Array(seat_cnt + 1)
  for item in data
    seats[item.seat_num - 1] = !!item.seat_seq

  out = ""
  line = ""
  for i in [0...seat_cnt]
    line = "[#{i < 9 && " " || ""}#{i + 1}:#{seats[i] && "O" || " "}] #{line}"
    line = "    #{line}" if i % 4 == 1
    if i % 4 == 3
      out = "#{out}\n#{line}"
      line = ""

  console.log out

if require.main == module
  cli.parse {
    ym: ['ym', 'year and month. ex: 201408', 'string']
    bus: ['bus', 'bus number. ex: 541', 'string']
  }
  error_msg = "Invalid option. provide proper ym and bus option plz."

  cli.main (args, options) ->
    read options.ym, options.bus, (err, data) =>
      return this.fatal err if err?
      render data.seat, data.count
else
  module.exports = read
