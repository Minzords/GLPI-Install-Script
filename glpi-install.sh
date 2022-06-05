#!/bin/bash

Setup_Variables(){
	DBPASSWORD=$(whiptail --passwordbox "Definir le mot de passe pour MySQL" 10 100 3>&1 1>&2 2>&3)
	HOSTNAME=$(whiptail --inputbox "Definir le nom de domaine du GLPI" 10 100 3>&1 1>&2 2>&3)
}

Install_Deps(){
{
	echo -e "XXX\n0\nInstallation d'Apache... \nXXX"
	dnf install httpd -y
	echo -e "XXX\n25\nInstallation d'Apache... Fait.\nXXX"
	echo -e "XXX\n30\nInstallation d'MariaDB... \nXXX"
        dnf install mariadb-server -y
        echo -e "XXX\n50\nInstallation d'Mariabd... Fait.\nXXX"
	echo -e "XXX\n55\nInstallation de PHP... \nXXX"
	sudo dnf module enable php:8.0 -y
        dnf install php-cli php-fpm php-mbstring php-zip php-ldap php-intl php-gd php-curl php-xml php-mysqlnd php-bz2 php-opcache -y
        echo -e "XXX\n100\nInstallation de PHP... Fait.\nXXX"
} |whiptail --title "Installion des dépendances" --gauge "Merci de patienter." 6 60 0
}

Config_Services(){
{
	echo -e "XXX\n0\nLancement des services... \nXXX"
	systemctl enable --now httpd
	echo -e "XXX\n30\nLancement des services... \nXXX"
	systemctl enable --now mariadb
	echo -e "XXX\n75\nLancement des services... \nXXX"
	systemctl enable --now php-fpm
	echo -e "XXX\n100\nLancement des services... \nXXX"
} |whiptail --title "Lancement des services" --gauge "Merci de patienter." 6 60 0
}


Secure_Mysql(){
{
	echo -e "XXX\n0\nConfiguration de MariaDB... \nXXX"
	mysql_secure_installation <<EOF

y
${DBPASSWORD}
${DBPASSWORD}
y
y
y
y
EOF

echo -e "XXX\n30\nCreation de la base... \nXXX"
mysql -uroot -p${DBPASSWORD} -e "CREATE DATABASE glpi;"
echo -e "XXX\n75\nCreation de l'utilisateur... \nXXX"
mysql -uroot -p${DBPASSWORD} -e "CREATE USER glpi@localhost IDENTIFIED BY '${DBPASSWORD}';"
echo -e "XXX\n0\nReglage des paramètres... \nXXX"
mysql -uroot -p${DBPASSWORD} -e "GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'localhost';"
} |whiptail --title "Configuration de Mariadb" --gauge "Merci de patienter." 6 60 0
}


Install_GLPI(){
{
	echo -e "XXX\n0\nInstallation de GLPI... \nXXX"
	cd /var/www
	echo -e "XXX\n5\nInstallation de GLPI... \nXXX"
	wget -q  https://github.com/glpi-project/glpi/releases/download/10.0.0/glpi-10.0.0.tgz
	echo -e "XXX\n30\nInstallation de GLPI... \nXXX"
	tar xf glpi-10.0.0.tgz
	echo -e "XXX\n50\nInstallation de GLPI... \nXXX"
	rm glpi-10.0.0.tgz
	echo -e "XXX\n75\nInstallation de GLPI... \nXXX"
	chown -R apache:apache glpi
	echo -e "XXX\n100\nInstallation de GLPI... \nXXX"
} |whiptail --title "Installion de GLPI" --gauge "Merci de patienter." 6 60 0
}

Config_Apache(){
{
	echo -e "XXX\n5\nCreation du virtualhost... \nXXX"
	rm /etc/httpd/conf.d/userdir.conf
	echo -e "XXX\n30\nConfiguration du virtualhost... \nXXX"
	echo -e "<VirtualHost *:80>
    ServerName $HOSTNAME
    DocumentRoot /var/www/glpi
    <Directory /var/www/glpi>
        DirectoryIndex index.php
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        Require all granted
    </Directory>
</VirtualHost>
" > /etc/httpd/conf.d/glpi.conf

	echo -e "XXX\n50\nApplication... \nXXX"
	systemctl restart httpd
	echo -e "XXX\n75\nDesactivation du Firewall... \nXXX"
	systemctl stop firewalld
	systemctl disable firewalld
} |whiptail --title "Configuration d'Apache" --gauge "Merci de patienter." 6 60 0
}

Install_GLPI_Plugin(){
{
	cd /var/www/glpi/plugins
	echo -e "XXX\n30\nInstalation du plugin Treeview... \nXXX"
	wget -q https://github.com/pluginsGLPI/treeview/releases/download/1.10.0/glpi-treeview-1.10.0.tar.bz2
	        echo -e "XXX\n50\nInstalation du plugin FusionInventory... \nXXX"
	wget -q https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi10.0.0%2B1.0/fusioninventory-10.0.0+1.0.tar.bz2
	echo -e "XXX\n50\nInstalation du plugin News... \nXXX"
	wget -q https://github.com/pluginsGLPI/news/releases/download/1.10.3/glpi-news-1.10.3.tar.bz2
	echo -e "XXX\n75\nInstalation des plugins... \nXXX"
	tar xf glpi-treeview-1.10.0.tar.bz2
	tar xf fusioninventory-10.0.0+1.0.tar.bz2
	tar xf glpi-news-1.10.3.tar.bz2
	rm glpi-treeview-1.10.0.tar.bz2 fusioninventory-10.0.0+1.0.tar.bz2 glpi-news-1.10.3.tar.bz2
} |whiptail --title "Configuration d'Apache" --gauge "Merci de patienter." 6 60 0
}

Post_Install(){
	sed 's/enforcing/disabled/g' /etc/selinux/config
	whiptail --title "Installation Terminer" --msgbox "L'installation est entièrement terminé, merci de redemarrer" 8 78
	whiptail --title "Installation Terminer" --msgbox "Le GLPI est disponible à cette adresse: ${HOSTNAME}" 8 78
}

Main(){
	Setup_Variables;
	Install_Deps;
	Config_Services;
	Secure_Mysql;
	Install_GLPI;
	Install_GLPI_Plugin;
	Config_Apache;
}

Main
