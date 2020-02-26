FROM ubuntu

RUN apt-get update && apt-get install -y net-tools \
	git \
	ssh \
	vim \
	&& sed -ri "s/\#(PermitRootLogin ).+/\1yes/" /etc/ssh/sshd_config \
	&& sed -ri "s/\#(PasswordAuthentication ).+/\1 yes/" /etc/ssh/sshd_config \
	&& service ssh restart \
	&& useradd -s /bin/bash -m cramage \
	&& adduser cramage sudo \
	&& su - cramage -c "\
        mkdir ~/node_projects;\
        cd ~/node_projects; \
        git clone https://github.com/CraigR8806/SubscribeBot.git;\
        git checkout dockersupport;\
        cp properties/.app.properties properties/app.properties;\
        sed -ri 's%^(mongo\.admin\.password=).+%\1<adminpass>%' properties/app.properties;\
        sed -ri 's%^(mongo\.app\.user\.password=).+%\1<appuserpass>%' properties/app.properties;\
        sed -ri 's%^(discord\.bot\.token=).+%\1<bottoken>%' properties/app.properties;\
        bin/install.sh;\
        bin/start.sh"
