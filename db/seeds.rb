User.create(
        [
            {login: 'dispatcher', password: '123', user_type: 'dispatcher'},
            {login: 'driver1', password: '123', user_type: 'driver'},
            {login: 'driver2', password: '123', user_type: 'driver'}
        ]
)

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
