// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import Rails from "@rails/ujs"
Rails.start()
import "controllers"
import "bootstrap";
//= require jquery
//= require jquery_ujs
import { createPopper } from '@popperjs/core';
