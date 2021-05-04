# Valera

Automated crypto currency trading software for peatio 

# Configure

> rails runner God.new.reset_settings!

# Seed

> echo "create database valera_development;" | influx

# Start 

Start web server

> rails s

Run all bots with threads

> rails runner God.new.perform &


# Development

Run first bot only

> rails runner God.new.universes.first.perform_loop
