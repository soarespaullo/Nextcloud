#!/bin/bash
#
# ========================================================================
#  SCRIPT DE BACKUP AUTOMATIZADO DO NEXTCLOUD
# ------------------------------------------------------------------------
#  Autor:      Paulo Soares
#  Contato:    soarespaullo@proton.me
#  GitHub:     https://github.com/soarespaullo
#  Telegram:   @soarespaullo
#  Versão:     2.0
#  Criado em:  11/04/2025
# ------------------------------------------------------------------------
#  Descrição:
#      Este script realiza o backup automatizado dos arquivos e do banco
#      de dados do Nextcloud, com verificação de espaço, modo de
#      manutenção, compressão, e saída amigável com barra de progresso.
#
#  Requisitos:
#      - Executar como root (sudo)
#      - Utilitários: tar, gzip, pv, mysqldump, php (com Nextcloud OCC)
#
#  Licença: MIT
# ========================================================================
#
# === CORES PARA TERMINAL ===
VERMELHO="\e[31m" # VERMELHO
VERDE="\e[32m"	  # VERDE
AZUL="\e[34m"	    # AZUL
AMARELO="\e[33m"  # AMARELO
SEM_COR="\e[0m"   # SEM COR

# === VERIFICA SE É ROOT ===
if [[ "$EUID" -ne 0 ]]; then
  echo -e "${VERMELHO}Este script deve ser executado como root.${SEM_COR}"
  echo -e "${AMARELO}Execute como:${SEM_COR} sudo ./backup_nextcloud.sh"
  exit 1
fi

# === BANNER COLORIDO E INFORMATIVO ===
clear
echo -e "${AZUL}=============================================================${SEM_COR}"
echo -e "${AZUL} ${AMARELO}           BACKUP AUTOMATIZADO DO NEXTCLOUD        ${AZUL} ${SEM_COR}"
echo -e "${AZUL}=============================================================${SEM_COR}"
echo -e "${AZUL} ${VERDE} Este script realiza o backup dos arquivos e banco  ${AZUL} ${SEM_COR}"
echo -e "${AZUL} ${VERDE} de dados do Nextcloud com segurança e verificação. ${AZUL} ${SEM_COR}"
echo -e "${AZUL}=============================================================${SEM_COR}"
echo -e "${AZUL} ${AMARELO} Data e hora: ${SEM_COR}$(date +"%d/%m/%Y %H:%M:%S")    ${AZUL} ${SEM_COR}"
echo -e "${AZUL} ${AMARELO} Usuário atual: ${SEM_COR}$(whoami)                     ${AZUL} ${SEM_COR}"
echo -e "${AZUL}=============================================================${SEM_COR}"

# === SOLICITA E VALIDA O CAMINHO DO NEXTCLOUD ===
while true; do
  echo -ne "${AMARELO}Caminho do diretório do Nextcloud (ex: /var/www/nextcloud): ${SEM_COR}"
  read -e NEXTCLOUD_DIR
  if [[ -d "$NEXTCLOUD_DIR" ]]; then
    break
  else
    echo -e "${VERMELHO}Diretório inválido. Tente novamente.${SEM_COR}"
  fi
done

# === SOLICITA E VALIDA O CAMINHO DO BACKUP (OU CRIA SE NÃO EXISTIR) ===
while true; do
  echo -ne "${AMARELO}Caminho do destino do backup (ex: /media/backup): ${SEM_COR}"
  read -e BACKUP_DIR
  if [[ -d "$BACKUP_DIR" ]]; then
    break
  else
    echo -ne "${AMARELO}Diretório não existe. Deseja criá-lo? (s/n): ${SEM_COR}"
    read -e CRIAR_DIR
    if [[ "$CRIAR_DIR" == "s" || "$CRIAR_DIR" == "S" ]]; then
      mkdir -p "$BACKUP_DIR"
      if [[ $? -eq 0 ]]; then
        echo -e "${VERDE}Diretório criado com sucesso.${SEM_COR}"
        break
      else
        echo -e "${VERMELHO}Erro ao criar diretório. Verifique permissões.${SEM_COR}"
      fi
    fi
  fi
done

# === DADOS DO BANCO DE DADOS ===
echo -ne "${AMARELO}Host do MySQL (ex: localhost): ${SEM_COR}"
read -e DB_HOST

echo -ne "${AMARELO}Usuário do MySQL: ${SEM_COR}"
read -e DB_USER

echo -ne "${AMARELO}Nome do banco de dados do Nextcloud: ${SEM_COR}"
read -e DB_NAME

echo -ne "${AMARELO}Senha do MySQL: ${SEM_COR}"
read -s DB_PASS
echo

# === CRIA O DIRETÓRIO DE DESTINO SE NÃO EXISTIR ===
mkdir -p "$BACKUP_DIR"

# === VERIFICA ESPAÇO DISPONÍVEL EM GB ===
REQUIRED_SPACE_GB=$(du -s --block-size=1G "$NEXTCLOUD_DIR" | awk '{print $1}')
AVAILABLE_SPACE_GB=$(df -BG "$BACKUP_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')

echo -e "${AZUL}Espaço necessário: ${REQUIRED_SPACE_GB}GB${SEM_COR}"
echo -e "${AZUL}Espaço disponível: ${AVAILABLE_SPACE_GB}GB${SEM_COR}"

if (( REQUIRED_SPACE_GB > AVAILABLE_SPACE_GB )); then
  echo -e "${VERMELHO}Espaço insuficiente para o backup!${SEM_COR}"
  exit 1
fi
# === VERIFICA SE O 'pv' ESTÁ INSTALADO, SENÃO INSTALA COM SAÍDA AMIGÁVEL ===
if ! command -v pv &>/dev/null; then
  echo -e "${AMARELO}O utilitário 'pv' não está instalado. Iniciando instalação...${SEM_COR}"
  
  # Atualiza repositórios silenciosamente
  apt update -qq
  
  # === INSTALA 'PV' SILENCIOSAMENTE, MOSTRANDO UMA BARRA DE PROGRESSO FAKE ===
  echo -ne "${AZUL}Instalando 'pv'...${SEM_COR}"
  apt install -y pv &> /dev/null
  
  if [[ $? -eq 0 ]]; then
    echo -e "\r${VERDE}✔ 'pv' instalado com sucesso.${SEM_COR}"
  else
    echo -e "\r${VERMELHO}✘ Falha ao instalar o 'pv'. Verifique sua conexão ou permissões.${SEM_COR}"
    exit 1
  fi
else
  echo -e "${VERDE}'pv' já está instalado.${SEM_COR}"
fi

# === PERGUNTA SOBRE MODO DE MANUTENÇÃO ===
echo -ne "${AMARELO}Você deseja ativar o modo de manutenção antes do backup? (s/n): ${SEM_COR}"
read -e ATIVAR_MANUTENCAO
if [[ "$ATIVAR_MANUTENCAO" == "s" || "$ATIVAR_MANUTENCAO" == "S" ]]; then
  echo -e "${AMARELO}Ativando o modo de manutenção do Nextcloud...${SEM_COR}"
  sudo -u www-data php "$NEXTCLOUD_DIR"/occ maintenance:mode --on > /dev/null && \
  echo -e "${VERDE}Modo de manutenção ativado com sucesso.${SEM_COR}"
fi

# === GERA UM NOME AUTOMÁTICO PARA O BACKUP ===
BACKUP_NAME="${DB_NAME}_backup_$(date +'%d-%m-%Y_%H:%M:%S').tar.gz"

# === BACKUP DOS ARQUIVOS DO NEXTCLOUD COM BARRA DE PROGRESSO ===
echo -e "${VERDE}Iniciando backup dos arquivos do Nextcloud...${SEM_COR}"

PARENT_DIR=$(dirname "$NEXTCLOUD_DIR")
BASE_DIR=$(basename "$NEXTCLOUD_DIR")
TOTAL_SIZE=$(du -sb "$NEXTCLOUD_DIR" | awk '{print $1}')

tar -C "$PARENT_DIR" -cf - "$BASE_DIR" | pv -p -s "$TOTAL_SIZE" | gzip > "$BACKUP_DIR/$BACKUP_NAME"
echo -e "\n${VERDE}Backup dos arquivos concluído.${SEM_COR}"

# === BACKUP DO BANCO DE DADOS COM BARRA DE PROGRESSO ===
echo -e "${VERDE}Iniciando backup do banco de dados...${SEM_COR}"
DUMP_FILE="/tmp/${DB_NAME}_dump.sql"

# === REALIZA O DUMP DO BANCO DE DADOS, REDIRECIONANDO A SAÍDA DE ERRO ===
mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null > "$DUMP_FILE"
if [[ $? -ne 0 ]]; then
  echo -e "${VERMELHO}Erro ao gerar o dump do banco. Verifique as credenciais.${SEM_COR}"

 # === DESATIVA O MODO DE MANUTENÇÃO CASO O BACKUP FALHE ===
  if [[ "$ATIVAR_MANUTENCAO" == "s" || "$ATIVAR_MANUTENCAO" == "S" ]]; then
    echo -e "${AMARELO}Desativando o modo de manutenção do Nextcloud...${SEM_COR}"
    sudo -u www-data php "$NEXTCLOUD_DIR"/occ maintenance:mode --off > /dev/null && \
    echo -e "${VERDE}Modo de manutenção desativado com sucesso.${SEM_COR}"
  fi
  exit 1
fi

DUMP_SIZE=$(stat -c%s "$DUMP_FILE")
pv -p -s "$DUMP_SIZE" "$DUMP_FILE" | gzip > "$BACKUP_DIR/${DB_NAME}_backup.sql.gz"
rm "$DUMP_FILE"
echo -e "\n${VERDE}Backup do banco de dados concluído.${SEM_COR}"

# === DESATIVA O MODO DE MANUTENÇÃO ===
if [[ "$ATIVAR_MANUTENCAO" == "s" || "$ATIVAR_MANUTENCAO" == "S" ]]; then
  echo -e "${AMARELO}Desativando o modo de manutenção do Nextcloud...${SEM_COR}"
  sudo -u www-data php "$NEXTCLOUD_DIR"/occ maintenance:mode --off > /dev/null && \
  echo -e "${VERDE}Modo de manutenção desativado com sucesso.${SEM_COR}"
fi

# === RESUMO FINAL COM FORMATAÇÃO COLORIDA ===
echo -e "${AZUL}=================================================================${SEM_COR}"
echo -e "${AZUL} ${VERDE}            BACKUP CONCLUÍDO COM SUCESSO                ${AZUL} ${SEM_COR}"
echo -e "${AZUL}=================================================================${SEM_COR}"
echo -e "${AZUL} ${AMARELO} Arquivos salvos em:${SEM_COR}                        ${AZUL} ${SEM_COR}"
echo -e "${AZUL} ${SEM_COR}$BACKUP_DIR/$BACKUP_NAME" 
echo -e "${AZUL} ${SEM_COR}$BACKUP_DIR/${DB_NAME}_backup.sql.gz" 
echo -e "${AZUL}=================================================================${SEM_COR}"
echo -e "${AZUL} ${AMARELO} Tamanho do backup de arquivos:${SEM_COR} $(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)${AZUL} ${SEM_COR}"
echo -e "${AZUL} ${AMARELO} Tamanho do banco de dados:${SEM_COR} $(du -h "$BACKUP_DIR/${DB_NAME}_backup.sql.gz" | cut -f1)${AZUL} ${SEM_COR}"
echo -e "${AZUL} ${AMARELO} Data e hora:${SEM_COR}$(date +"%d/%m/%Y %H:%M:%S") ${AZUL} ${SEM_COR}"
echo -e "${AZUL}=================================================================${SEM_COR}"

# === FIM DO SCRIPT ===
echo -e "${VERDE}O script foi executado com sucesso.${SEM_COR}"
