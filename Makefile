SYMLINKS := slurm.conf slurmdbd.conf docker-compose.yml docker-entrypoint.sh register_cluster.sh
.PHONY = prod prod_symlinks test_symlinks test run debug clean init password

all:
	echo "Please select a specific target"

test: test_symlinks
	docker build -t slurm-docker-cluster-ubuntu_test .

prod: prod_symlinks
	docker build -t slurm-docker-cluster-ubuntu .

run:
	nvidia-docker-compose down
	nvidia-docker-compose up -d
	./register_cluster.sh

debug:
	nvidia-docker-compose down
	nvidia-docker-compose up

test_symlinks:
	$(foreach FILE,$(SYMLINKS), $(shell ln -sf $(FILE)_test $(FILE)))

prod_symlinks:
	@echo "Are you entirely sure you want to rebuild the production container? If not, press Ctrl-C now; otherwise, press enter"
	@read n
	@echo "Really?"
	@read n
	@git status
	@printf "\n\n^^^^^^^^^^^^^^^^^^^^^^^^\n"
	@echo "Git shows this. Do you see uncommitted files? If so, reconsider what you're doing"
	@read n
	@echo "Fine, but it's your fault if this whole system breaks"
	@sleep 2
	@echo "Building...may Richard Stallman have mercy on your soul"
	$(foreach FILE,$(SYMLINKS), $(shell ln -sf $(FILE)_prod $(FILE)))

password: prod_password test_password

test_password:
	pswd="$$(cat mysql_password.txt)" && echo $$pswd; \
	if test $$(grep MYSQL_PASSWORD: docker-compose.yml_test | wc -l) = 0; then \
	echo "got here" && sed -e '/MYSQL_RANDOM_ROOT_PASSWORD: "yes"/a \      MYSQL_PASSWORD: ' docker-compose.yml_test > test.txt && sed "/MYSQL_PASSWORD: / s/$$/$$pswd/" test.txt > docker-compose.yml_test && rm -f test.txt; \
	fi && pswd=""

prod_password:
	pswd="$$(cat mysql_password.txt)" && echo $$pswd; \
	if test $$(grep MYSQL_PASSWORD: docker-compose.yml_prod | wc -l) = 0; then \
	echo "got here" && sed -e '/MYSQL_RANDOM_ROOT_PASSWORD: "yes"/a \      MYSQL_PASSWORD: ' docker-compose.yml_prod > test2.txt && sed "/MYSQL_PASSWORD: / s/$$/$$pswd/" test2.txt > docker-compose.yml_prod && rm -f test2.txt; \
	fi && pswd=""

strip_password: strip_prod_password strip_test_password

strip_prod_password:
	sed -i --follow-symlinks -e '/MYSQL_PASSWORD:/d' docker-compose.yml_prod
strip_test_password:
	sed -i --follow-symlinks -e '/MYSQL_PASSWORD:/d' docker-compose.yml_test

clean:
	docker-compose rm -sf
	@docker volume rm slurmdockercluster_etc_munge slurmdockercluster_etc_slurm slurmdockercluster_slurm_jobdir slurmdockercluster_var_lib_mysql slurmdockercluster_var_log_slurm
	@docker volume rm slurmdockercluster_etc_munge_test slurmdockercluster_etc_slurm_test slurmdockercluster_slurm_jobdir_test slurmdockercluster_var_lib_mysql_test slurmdockercluster_var_log_slurm_test
	@docker volume rm nihti_etc_munge nihti_etc_slurm nihti_slurm_jobdir nihti_var_lib_mysql nihti_var_log_slurm
	@docker volume rm nihti_etc_munge_test nihti_etc_slurm_test nihti_slurm_jobdir_test nihti_var_lib_mysql_test nihti_var_log_slurm_test
	$(foreach FILE,$(SYMLINKS), $(shell unlink $(FILE)))

init: .git/hooks/pre-commit

.git/hooks/pre-commit: .pre-commit.sh
	cp .pre-commit.sh .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit

mysql_password.txt:
	openssl rand -base64 32 > mysql_password.txt
