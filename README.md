# Template development environment
This is the environment template to re-use between projects.

## Bash commands
We use [bashly](https://bashly.dannyb.co/) to generate a set of bash commands to simplify the overall Docker commands to run and provide a quick way to initialize or update the environment.

## Docker Compose
We use [Docker Compose](https://docs.docker.com/compose/reference/) to create a set of Docker containers to replicate a production environment as closely as possible.

# Development environment creation

## Repositories

1. Clone this repository under the name you want the new project to be. (example: `cocoapp.dev.environment`)
2. Create a new repository under the Appwapp's organization: https://github.com/appwapp
3. Create any sub-repositories for the applications that will be developped and pulled under `src/` (example: `cocoapp.api.webapp`, which will be pulled at `src/api.webapp`)

**Note**: Also add access to the `appwapp/developers` team (or any other team).

## Docker Compose

The current `docker-compose.yml` already contains a `nginx` service, which will be used in most projects.

Anything related to the docker containers should be stored in `.docker/`. Although a project-specific `Dockerfile` should be put into the application repository instead.

See some [available recipes](docs/recipes) to start from.

## Bashly

Most bash commands are already generated under `.bashly/src` and `.bashly/src/lib`. Project-specific commands will need to be added.

See some [available recipes](docs/recipes) to start from.

The configuration file also needs to be configured: `bashly.ini`.

## Environment documentation and recipes

Couple of things to search & replace in the `docs/*.md`:

- `{TEMPLATE_COMMAND}`: Command that will be used (example: `coco`)
- `{TEMPLATE_DOMAIN}`: Test domain used (example: `cocoapp.test`)
- `{TEMPLATE_PROJECT_NAME}`: Full project name (example: `Cocoapp`)
- `{TEMPLATE_REPOSITORY}`: Repository name (example: `cocoapp.dev.environment`)

**Optional**:

- `{TEMPLATE_DATABASE}`: Name of the database used

## Cleanup

Once everything is set up, time for a cleanup:

- Remove recipes
- Remove this `readme.md` (`docs/readme.md` will take over)

```bash
rm -rf docs/recipes && rm readme.md
```
