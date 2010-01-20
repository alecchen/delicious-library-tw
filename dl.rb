require 'rubygems'
require 'sinatra'

get '/onca/xml' do
    p "Keywords = " + params[:Keywords]
    "DL"
end
