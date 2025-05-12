## 🔐 1. Crie o arquivo /root/.my.cnf com as credenciais do MySQL
Esse arquivo armazena o usuário e a senha do MySQL de forma segura (permite login sem prompt):

```
nano /root/.my.cnf
```
Adicione o seguinte conteúdo (ajuste o user e password conforme necessário):

```
[client]
user=root
password=SUASENHAAQUI
```

Depois, proteja o arquivo com permissões restritas:

```
chmod 600 /root/.my.cnf
```
