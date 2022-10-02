# Redis

## Docker compose service

```yml
  # Redis Service
  redis:
    image: redis:7-alpine
    command: ["redis-server", "--appendonly", "yes"]
    volumes:
      - redisdata:/data
  
# Volumes
volumes:

  redisdata:
```
