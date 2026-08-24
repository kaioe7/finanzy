# Finanzy

Sistema de controle financeiro pessoal com painel de cliente e administração.

## Como abrir

Inicie o servidor local na pasta:

```powershell
node server.js
```

Depois abra `http://127.0.0.1:4173`. Evite abrir `index.html` diretamente.

## Publicação na Vercel

O projeto inclui `vercel.json` e pode ser publicado diretamente como site estático.
Após publicar, adicione o domínio gerado em **Supabase > Authentication > URL
Configuration > Site URL** para que confirmação de e-mail e recuperação de senha
retornem ao endereço correto.

## Banco de dados Supabase

O projeto está configurado para usar Supabase. Antes do primeiro cadastro, abra o
**SQL Editor** do projeto, copie todo o conteúdo de `supabase-schema.sql` e clique
em **Run**. Isso cria as tabelas e as regras que isolam os dados de cada cliente.

Depois, crie sua conta normalmente na tela inicial. Para transformar sua própria
conta em administradora, execute no SQL Editor, trocando o e-mail:

```sql
update public.profiles set role = 'admin' where email = 'seu@email.com';
```

A configuração pública da conexão fica em `supabase-config.js`. Nunca coloque a
chave `service_role` nesse arquivo.

## Recursos

- Login, cadastro e perfis de cliente/administrador
- Receitas, despesas, categorias, busca e filtros
- Gastos fixos e metas financeiras
- Painel mensal e gráficos de evolução
- Relatório mensal imprimível em PDF
- Compartilhamento de resumo pelo WhatsApp
- Tema escuro e claro, design responsivo
- Dados persistidos no PostgreSQL do Supabase
- Autenticação segura, sessão persistente e isolamento por usuário (RLS)

## Observação para comercialização

Antes de vender, publique o site em HTTPS, configure domínio e recuperação de
senha, revise os e-mails de autenticação, os backups, os termos de uso e a LGPD.
