require 'digest'

default_pwd = User.encrypt_password('123')

User.create(
        [
            {login: 'dispatcher', password: default_pwd, user_type: 'dispatcher'},
            {login: 'driver1', password: default_pwd, user_type: 'driver'},
            {login: 'driver2', password: default_pwd, user_type: 'driver'}
        ]
)

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
