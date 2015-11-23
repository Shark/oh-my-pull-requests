# oh-my-pull-requests

Ruby app which checks the status of pull requests on Github and visualizes the result by setting the color of a [blink(1)](https://blink1.thingm.com/) notification light.

## Installation

To use locally:
```
git clone https://github.com/Shark/oh-my-pull-requests.git
bundle install
cp config/config.yml.dist config/config.yml # and add your Github API token
./oh-my-pull-requests.rb
```

To build a Docker image and run it in a container:
```
git clone https://github.com/Shark/oh-my-pull-requests.git
./docker_build.sh
docker run -d -v $(pwd)/config:/usr/src/app/config:ro sh4rk/oh-my-pull-requests
```
## Usage

1. Put your configuration file in `config/config.yml`. When using the docker container remember to map the local config directory into the container using the above command.

2. Run `./oh-my-pull-requests.sh` or create a Docker container as outlined above.

## Contributing
1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request! :)

## History

- v0.1.0 (2015-11-23): initial version

## License

This project is licensed under the Apache 2.0 License. See LICENSE for details.
