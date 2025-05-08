#!/bin/bash

# === CORES PARA TERMINAL ===
RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
YELLOW="\e[33m"
NC="\e[0m" # No Color

# === VERIFICA SE É ROOT ===
if [[ "$EUID" -ne 0 ]]; then
  echo -e "${RED}Este script deve ser executado como root.${NC}"
  echo -e "${YELLOW}Execute como:${NC} sudo ./backup_nextcloud.sh"
  exit 1
fi

# === BANNER COLORIDO E INFORMATIVO ===
clear
echo -e "${BLUE}=============================================================${NC}"
echo -e "${BLUE} ${YELLOW}           BACKUP AUTOMATIZADO DO NEXTCLOUD        ${BLUE} ${NC}"
echo -e "${BLUE}=============================================================${NC}"
echo -e "${BLUE} ${GREEN} Este script realiza o backup dos arquivos e banco  ${BLUE} ${NC}"
echo -e "${BLUE} ${GREEN} de dados do Nextcloud com segurança e verificação. ${BLUE} ${NC}"
echo -e "${BLUE}=============================================================${NC}"
echo -e "${BLUE} ${YELLOW} Data e hora: ${NC}$(date +"%d/%m/%Y %H:%M:%S")    ${BLUE} ${NC}"
echo -e "${BLUE} ${YELLOW} Usuário atual: ${NC}$(whoami)                     ${BLUE} ${NC}"
echo -e "${BLUE}=============================================================${NC}"

# === SOLICITA INFORMAÇÕES AO USUÁRIO ===
echo -ne "${YELLOW}Caminho do diretório do Nextcloud (ex: /var/www/nextcloud): ${NC}"
read -e NEXTCLOUD_DIR

echo -ne "${YELLOW}Caminho do destino do backup (ex: /backups/nextcloud): ${NC}"
read -e BACKUP_DIR

# === DADOS DO BANCO DE DADOS ===
echo -ne "${YELLOW}Host do MySQL (ex: localhost): ${NC}"
read -e DB_HOST

echo -ne "${YELLOW}Usuário do MySQL: ${NC}"
read -e DB_USER

echo -ne "${YELLOW}Nome do banco de dados do Nextcloud: ${NC}"
read -e DB_NAME

echo -ne "${YELLOW}Senha do MySQL: ${NC}"
read -s -e DB_PASS
echo

# === CRIA O DIRETÓRIO DE DESTINO SE NÃO EXISTIR ===
mkdir -p "$BACKUP_DIR"

# === VERIFICA ESPAÇO DISPONÍVEL EM GB ===
REQUIRED_SPACE_GB=$(du -s --block-size=1G "$NEXTCLOUD_DIR" | awk '{print $1}')
AVAILABLE_SPACE_GB=$(df -BG "$BACKUP_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')

echo -e "${BLUE}Espaço necessário: ${REQUIRED_SPACE_GB}GB${NC}"
echo -e "${BLUE}Espaço disponível: ${AVAILABLE_SPACE_GB}GB${NC}"

if (( REQUIRED_SPACE_GB > AVAILABLE_SPACE_GB )); then
  echo -e "${RED}Espaço insuficiente para o backup!${NC}"
  exit 1
fi

# === VERIFICA SE O 'pv' ESTÁ INSTALADO, SENÃO INSTALA ===
if ! command -v pv &>/dev/null; then
  echo -e "${YELLOW}Instalando 'pv' para barra de progresso...${NC}"
  apt update && apt install -y pv
fi

# === PERGUNTA SOBRE MODO DE MANUTENÇÃO ===
echo -ne "${YELLOW}Você deseja ativar o modo de manutenção antes do backup? (s/n): ${NC}"
read -e ATIVAR_MANUTENCAO
if [[ "$ATIVAR_MANUTENCAO" == "s" || "$ATIVAR_MANUTENCAO" == "S" ]]; then
  echo -e "${YELLOW}Ativando o modo de manutenção do Nextcloud...${NC}"
  sudo -u www-data php "$NEXTCLOUD_DIR"/occ maintenance:mode --on > /dev/null && \
  echo -e "${GREEN}Modo de manutenção ativado com sucesso.${NC}"
fi

# === GERA UM NOME AUTOMÁTICO PARA O BACKUP ===
BACKUP_NAME="${DB_NAME}_backup_$(date +'%Y%m%d_%H%M%S').tar.gz"

# === BACKUP DOS ARQUIVOS DO NEXTCLOUD COM BARRA DE PROGRESSO ===
echo -e "${GREEN}Iniciando backup dos arquivos do Nextcloud...${NC}"

PARENT_DIR=$(dirname "$NEXTCLOUD_DIR")
BASE_DIR=$(basename "$NEXTCLOUD_DIR")
TOTAL_SIZE=$(du -sb "$NEXTCLOUD_DIR" | awk '{print $1}')

tar -C "$PARENT_DIR" -cf - "$BASE_DIR" | pv -p -s "$TOTAL_SIZE" | gzip > "$BACKUP_DIR/$BACKUP_NAME"
echo -e "\n${GREEN}Backup dos arquivos concluído.${NC}"

# === BACKUP DO BANCO DE DADOS COM BARRA DE PROGRESSO ===
echo -e "${GREEN}Iniciando backup do banco de dados...${NC}"
DUMP_FILE="/tmp/${DB_NAME}_dump.sql"

mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$DUMP_FILE"
if [[ $? -ne 0 ]]; then
  echo -e "${RED}Erro ao gerar o dump do banco. Verifique as credenciais.${NC}"
  exit 1
fi

DUMP_SIZE=$(stat -c%s "$DUMP_FILE")
pv -p -s "$DUMP_SIZE" "$DUMP_FILE" | gzip > "$BACKUP_DIR/${DB_NAME}_backup.sql.gz"
rm "$DUMP_FILE"
echo -e "\n${GREEN}Backup do banco de dados concluído.${NC}"

# === DESATIVA O MODO DE MANUTENÇÃO ===
if [[ "$ATIVAR_MANUTENCAO" == "s" || "$ATIVAR_MANUTENCAO" == "S" ]]; then
  echo -e "${YELLOW}Desativando o modo de manutenção do Nextcloud...${NC}"
  sudo -u www-data php "$NEXTCLOUD_DIR"/occ maintenance:mode --off > /dev/null && \
  echo -e "${GREEN}Modo de manutenção desativado com sucesso.${NC}"
fi

# === RESUMO FINAL COM FORMATAÇÃO COLORIDA ===
echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE} ${GREEN}            BACKUP CONCLUÍDO COM SUCESSO                 ${BLUE} ${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE} ${YELLOW} Arquivos salvos em:${NC}                               ${BLUE}│${NC}"
echo -e "${BLUE} ${NC}$BACKUP_DIR/$BACKUP_NAME" 
echo -e "${BLUE} ${NC}$BACKUP_DIR/${DB_NAME}_backup.sql.gz" 
echo -e "${BLUE}=========================================================================${NC}"
echo -e "${BLUE} ${YELLOW} Tamanho do backup de arquivos:${NC} $(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)${BLUE} ${NC}"
echo -e "${BLUE} ${YELLOW} Tamanho do banco de dados:${NC} $(du -h "$BACKUP_DIR/${DB_NAME}_backup.sql.gz" | cut -f1)${BLUE} ${NC}"
echo -e "${BLUE} ${YELLOW} Data e hora:${NC}$(date +"%d/%m/%Y %H:%M:%S") ${BLUE}│${NC}"
echo -e "${BLUE}============================================================================${NC}"

# === FIM DO SCRIPT ===
echo -e "${GREEN}O script foi executado com sucesso.${NC}"
