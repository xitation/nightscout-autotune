# nightscout-autotune
Use `oref0-autotune` on a nightscout instance.

## Description
A small nodejs library that uses the oref0 reference implementation to run autotune on a Nightscout instance.
It can be run as either a nodejs application or a Docker container. 

The Docker container now supports running autotune on a configurable schedule using cron, while maintaining full backward compatibility with one-shot execution.

## Getting started
If you want to use the dockerized version of this app, just pull `houthacker42/wearenotwaiting/nightscout-autotune`, after you have ensured that the required dependencies have been installed.

Or use one of the example docker-compose files found in the docker-compose directory.

### Dependencies
#### Dockerized app
  * *docker*: https://docs.docker.com/engine/install/

#### Standalone app
  * Node Version Manager: https://github.com/nvm-sh/nvm
  * nodejs

### Supported architectures
#### Dockerized app
  * linux/amd64
  * linux/arm64

### Standalone
  * Native builds

### Installation
#### Dockerized app
```bash
# Just pull the image
$ docker image pull ghcr.io/houthacker/nightscout-autotune:latest
```

#### Standalone
  1. Install *nvm*: Head over to https://github.com/nvm-sh/nvm for installation instructions and install `nvm` and the latest version of `nodejs`. 
  
  2. Install nightscout-autotune
  ```bash
  # Clone this repository and change to its directory
  $ git clone https://github.com/houthacker/nightscout-autotune.git

  $ cd nightscout-autotune

  # Use `npm install -g` if you want to install it globally.
  $ npm install -g

  # Clone the autotune repository and cd into its directory.
  $ git clone git clone --branch v0.7.1 https://github.com/openaps/oref0.git

  $ cd oref0

  # Install oref0
  $ npm run global-install

  ```

# Usage

## Docker
Docker can be run using CLI one-shot runs to generate a set of point in time data which you can then manually extract from the container with the steps defined in Option 1.

OR

You can run this as a service with the provided docker-compose config and a web server to allow viewing the generate profile info which can be configured to run on a cron schedule if you follow option 2.

### Docker variables:
#### New Cron-Specific Variables

- **`CRON_SCHEDULE`**: Cron expression defining when to run autotune
  - Format: Standard cron syntax (minute hour day month weekday)
  - If not set: Container runs once and exits (original behavior)
  - Example: `"0 2 * * *"` (daily at 2:00 AM)

- **`RUN_ON_STARTUP`**: Whether to run autotune immediately when container starts
  - Values: `true` or `false`
  - Default: `false`
  - Only applies when `CRON_SCHEDULE` is set

#### Existing Variables (Unchanged)
All existing environment variables work exactly as before:
- `NS_HOST` (required)
- `AUTOTUNE_DAYS` (required)
- `UAM_AS_BASAL` (required)
- `NS_API_SECRET` (optional)
- `NS_TOKEN` (optional)
- `NS_PROFILE` (optional)
- `MIN_5MIN_CARBIMPACT` (optional)
- `AUTOSENS_MIN` (optional)
- `AUTOSENS_MAX` (optional)
- `INSULIN_TYPE` (optional)
- `OPENAPS_WORKDIR` (optional, default: `/tmp/autotune`)
- `HTML_EXPORT` (optional, default: `false`)

### Option 1: Docker via cli:
Run the image without arguments to see its usage description and examples
```bash
$ docker run --rm ghcr.io/houthacker/nightscout-autotune:latest
```

#### Extract HTML page with recommendations to your linux pc and view it in your browser
```bash
$ docker run <arguments> ghcr.io/houthacker/nightscout-autotune:latest
$ docker cp $(docker ps -a|grep nightscout-autotune|awk '{print $1}')/tmp/autotune/autotune/autotune_recommendations.html <local path>
$ open <local path>
```

### Option2: Docker compose with web server and cron:
When using the docker-compose method, the container will run as a background service and will run the profile generation task via configured cron schedule. 
You can view the generated profile using a web browser making it easy and convinient to have a new updated profile generated once a day and easy to view while you work out your new AAPS/OpenAPS profiles.

```
services:
  nightscout-autotune:
    image: ghcr.io/houthacker/nightscout-autotune:latest
    container_name: nightscout-autotune
    restart: unless-stopped
    environment:
      CRON_SCHEDULE: "0 2 * * *"        # Daily at 2:00 AM
      RUN_ON_STARTUP: "true"
      NS_HOST: "https://my.nightscout.host"
      AUTOTUNE_DAYS: "7"                # Shorter analysis window
      UAM_AS_BASAL: "false"
      HTML_EXPORT: "true"
      NS_TOKEN: "${NS_TOKEN}"
    volumes:
      - ./autotune-data:/tmp/autotune

  autotune-web:
    image: nginx:alpine
    container_name: nightscout-autotune-web
    restart: unless-stopped
    ports:
      - "8080:80"                       # Access at http://localhost:8080
    volumes:
      - ./autotune-data:/usr/share/nginx/html/reports:ro  # Read-only mount
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/index.html:/usr/share/nginx/html/index.html:ro
    depends_on:
      - autotune-daily

```

Make any environment changes require to suit your setup, e.g. make sure the NS_HOST: points to your NS URL and that if you have a locked down deployment you define the NS_TOKEN.

You can configure when the background job runs by modifying the CRON_SCHEDULE value, if you are not across how to define a cron schedule, I recommend this site to help - https://crontab.guru/.

After modifying your docker-compose.yml to match your environmet run the following to bring up the containers:

```
$ docker compose up -d
```

Then open a web browser and browse to http://[your server ip running docker]:8080

## Standalone app
Run the app without arguments or with `--help` to see its usage description and examples.
```bash
# If installed globally
$ nightscout-autotune --help

# If installed locally
$ ./bin/app.sh --help
```

### Autotune output
The output of `oref0-autotune` is printed to the console, and looks like the example below.
```bash
... previous logging omitted

Autotune pump profile recommendations:
---------------------------------------------------------
Recommendations Log File: /tmp/autotune/autotune/autotune_recommendations.log

Parameter      | Pump        | Autotune    | Days Missing
---------------------------------------------------------
ISF [mg/dL/U]  | 15.000      | 17.315      |
Carb Ratio[g/U]| 15.500      | 14.728      |
  00:00        | 0.250       | 0.306       | 1           
  01:00        | 0.250       | 0.307       | 1           
  02:00        | 0.250       | 0.307       | 1           
  03:00        | 0.300       | 0.360       | 0           
  04:00        | 0.300       | 0.360       | 1           
  05:00        | 0.300       | 0.357       | 0           
  06:00        | 0.300       | 0.348       | 1           
  07:00        | 0.350       | 0.396       | 1           
  08:00        | 0.350       | 0.245       | 0           
  09:00        | 0.350       | 0.245       | 0           
  10:00        | 0.350       | 0.245       | 0           
  11:00        | 0.350       | 0.276       | 0           
  12:00        | 0.350       | 0.402       | 1           
  13:00        | 0.350       | 0.402       | 1           
  14:00        | 0.350       | 0.388       | 0           
  15:00        | 0.350       | 0.406       | 1           
  16:00        | 0.350       | 0.406       | 1           
  17:00        | 0.350       | 0.406       | 1           
  18:00        | 0.340       | 0.396       | 1           
  19:00        | 0.350       | 0.406       | 1           
  20:00        | 0.330       | 0.387       | 1           
  21:00        | 0.300       | 0.358       | 1           
  22:00        | 0.300       | 0.309       | 0           
  23:00        | 0.300       | 0.296       | 0 
```
