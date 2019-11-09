# ansible_mongo_role
Ansible mongo role


wget https://raw.githubusercontent.com/vitkhab/gce_test/c98d97ea79bacad23fd26106b52dee0d21144944/.travis.yml
# генерируем ключ для подключения по SSH
ssh-keygen -t rsa -f google_compute_engine -C 'travis' -q -N ''
# Создаем ключ в метадате проекта infra в GCP
pbcopy < google_compute_engine.pub # OSX specific command

# Должен быть предварительно создан сервисный аккаунт и скачаны креды (credentials.json)
# Должна быть предварительно подключена данная репа в тревисе
travis login --com
travis encrypt GCE_SERVICE_ACCOUNT_EMAIL='ci-test@infra-179032.iam.gserviceaccount.com' --add --com
travis encrypt GCE_CREDENTIALS_FILE="$(pwd)/credentials.json" --add --com
travis encrypt GCE_PROJECT_ID='infra-179032' --add --com

# шифруем файлы
tar cvf secrets.tar credentials.json google_compute_engine
travis encrypt-file secrets.tar --add --com

# пушим и проверяем изменения
git commit -m 'Added Travis integration'
git push