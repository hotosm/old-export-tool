# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120625082806) do

  create_table "downloads", :force => true do |t|
    t.string   "name"
    t.string   "size"
    t.integer  "run_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.text     "url"
  end

  add_index "downloads", ["run_id"], :name => "index_downloads_on_run_id"

  create_table "jobs", :force => true do |t|
    t.string   "name"
    t.float    "latmin"
    t.float    "latmax"
    t.float    "lonmin"
    t.float    "lonmax"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.text     "description"
    t.integer  "region_id"
  end

  create_table "regions", :force => true do |t|
    t.string   "internal_name"
    t.string   "name"
    t.float    "left"
    t.float    "bottom"
    t.float    "right"
    t.float    "top"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "runs", :force => true do |t|
    t.string   "state"
    t.string   "comment"
    t.integer  "job_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "runs", ["job_id"], :name => "index_runs_on_job_id"

  create_table "tags", :force => true do |t|
    t.string   "key"
    t.string   "geometrytype"
    t.boolean  "default"
    t.integer  "job_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "tags", ["job_id"], :name => "index_tags_on_job_id"

end
