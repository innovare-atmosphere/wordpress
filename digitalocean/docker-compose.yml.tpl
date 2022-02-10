version: '3.1'

services:

  wordpress:
    image: wordpress
    restart: always
    ports:
      - 8080:80
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wp_user
      WORDPRESS_DB_PASSWORD: ${database_password}
      WORDPRESS_DB_NAME: wp_db
    volumes:
      - wordpress:/var/www/html
      - ./themes:/var/www/html/wp-content/themes/
      - ./plugins:/var/www/html/wp-content/plugins/

  db:
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_DATABASE: wp_db
      MYSQL_USER: wp_user
      MYSQL_PASSWORD: ${database_password}
      MYSQL_RANDOM_ROOT_PASSWORD: '${database_password}'
    volumes:
      - db:/var/lib/mysql

volumes:
  wordpress:
  db: