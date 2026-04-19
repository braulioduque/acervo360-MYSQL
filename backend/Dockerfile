FROM node:20-slim

WORKDIR /app

# Instala dependências básicas
COPY package*.json ./
RUN npm install

# Copia o restante do código
COPY . .

# Cria a pasta de uploads caso não exista
RUN mkdir -p uploads

EXPOSE 3000

CMD ["npm", "start"]
