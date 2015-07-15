# encoding: UTF-8

require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'expert'
Expert.environment.require_all

require 'grape'
require 'rack/test'
require 'rspec'
require 'rosette/core'
require 'rosette/integrations/rollbar_integration'
require 'pry-nav'
