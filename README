# Dockerpress

Wordpress running in single Docker container using PHP7, MariaDB and nginx. With every new container, always latest version of Wordpress is downloaded.

## How to run it
Just create new container from [pavelsterba/dockerpress](https://hub.docker.com/r/pavelsterba/dockerpress/) image.
```
docker run -itd --name dockerpress -p 80:80 pavelsterba/dockerpress
```

In this case, everything will be enclosed in container, so if you delete it, all data will be lost. If you want to have persistant Wordpress installation (**recomended**), mount some host folder to `/var/www` in container:
```
docker run -itd --name dockerpress -p 80:80 -v /var/www/my_site:/var/www pavelsterba/dockerpress
```
