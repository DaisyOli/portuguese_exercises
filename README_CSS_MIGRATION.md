# 🎨 CSS Component System - Usage Guide

## 🚀 **Quick Start**

Sua aplicação agora possui um sistema CSS profissional e escalável! Aqui está como usar os componentes:

---

## 📋 **Componentes Disponíveis**

### **🔘 BOTÕES**

```html
<!-- Botão principal -->
<a href="#" class="btn-giz">
  <i class="fas fa-plus"></i>
  <span>Ação Principal</span>
</a>

<!-- Variações de cor -->
<a href="#" class="btn-giz purple">Roxo</a>
<a href="#" class="btn-giz verde">Verde</a>  
<a href="#" class="btn-giz secondary">Cinza</a>

<!-- Tamanhos -->
<a href="#" class="btn-giz small">Pequeno</a>
<a href="#" class="btn-giz large">Grande</a>

<!-- Ações rápidas -->
<a href="#" class="btn-mini ver">Ver</a>
<a href="#" class="btn-mini editar">Editar</a>
<button class="btn-buscar">Buscar</button>
```

### **📋 HEADERS**

```html
<!-- Dashboard do professor -->
<div class="header-quadro">
  <div class="professor-info">
    <h1><i class="fas fa-icon"></i> Título</h1>
    <p>Descrição</p>
  </div>
  <div class="action-buttons">
    <!-- botões aqui -->
  </div>
</div>

<!-- Lista de atividades -->
<div class="header-atividades">
  <div class="header-info">
    <h1>Título</h1>
    <p>Descrição</p>
  </div>
  <div class="header-actions">
    <!-- ações aqui -->
  </div>
</div>

<!-- Atividade individual -->
<div class="header-atividade">
  <h1>Nome da Atividade</h1>
  <p>Descrição</p>
</div>
```

### **🃏 CARDS**

```html
<!-- Post-its (dashboard) -->
<div class="post-it">
  <h2><i class="fas fa-icon"></i> Título</h2>
  <p>Conteúdo do card...</p>
</div>

<!-- Variações de cor -->
<div class="post-it lavanda">Roxo claro</div>
<div class="post-it menta">Verde claro</div>
<div class="post-it pessego">Rosa claro</div>
<div class="post-it azul-gelo">Azul claro</div>

<!-- Card de atividade -->
<div class="card-atividade">
  <div class="card-header">
    <h3 class="card-title">Nome da Atividade</h3>
    <span class="card-level">A1</span>
  </div>
  <div class="card-content">
    <p class="card-description">Descrição...</p>
    <div class="card-meta">
      <span class="meta-item">
        <i class="fas fa-clock"></i> 10 min
      </span>
    </div>
  </div>
  <div class="card-actions">
    <a href="#" class="btn-mini ver">Ver</a>
  </div>
</div>

<!-- Métricas -->
<div class="card-metrica">
  <div class="metrica-icon">
    <i class="fas fa-users"></i>
  </div>
  <div class="metrica-numero">42</div>
  <div class="metrica-label">Estudantes</div>
</div>
```

### **📝 FORMULÁRIOS**

```html
<div class="form-container">
  <div class="form-card">
    <h2 class="form-title">
      <i class="fas fa-plus"></i>
      Nova Atividade
    </h2>
    
    <div class="form-section">
      <h3 class="section-title">
        <i class="fas fa-info"></i>
        Informações Básicas
      </h3>
      
      <div class="form-group">
        <label class="form-label">
          Título <span class="required">*</span>
        </label>
        <input type="text" class="form-input" placeholder="Digite o título">
      </div>
      
      <div class="form-group">
        <label class="form-label">Descrição</label>
        <textarea class="form-textarea" placeholder="Descreva a atividade"></textarea>
      </div>
      
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">Nível</label>
          <select class="form-select">
            <option>A1</option>
            <option>A2</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Tipo</label>
          <select class="form-select">
            <option>Quiz</option>
            <option>Exercício</option>
          </select>
        </div>
      </div>
    </div>
    
    <div class="form-actions">
      <button type="button" class="btn-form secondary">Cancelar</button>
      <button type="submit" class="btn-form primary">Salvar</button>
    </div>
  </div>
</div>
```

---

## 🛠️ **Utility Classes**

### **Layout**
```html
<div class="d-flex justify-between align-center gap-2">
  <span>Conteúdo</span>
  <button class="btn-mini">Ação</button>
</div>
```

### **Typography**
```html
<h2 class="font-display text-verde">Título</h2>
<p class="text-center text-muted">Texto centralizado</p>
```

### **Spacing**
```html
<div class="mt-3 mb-2 p-2">
  <span class="ml-1">Com espaçamentos</span>
</div>
```

### **Effects**
```html
<div class="card hover-lift shadow-lg rounded">
  Card com efeitos
</div>
```

---

## 🎨 **CSS Variables Disponíveis**

Use essas variáveis para customizações:

```css
/* Cores principais */
var(--quadro-verde)        /* #1e3a2e */
var(--giz-branco)          /* #f8f9fa */
var(--verde-destaque)      /* #2e7d32 */
var(--azul-acao)           /* #1976d2 */
var(--roxo-acao)           /* #7b1fa2 */

/* Post-it colors */
var(--post-it-creme)       /* #fff3e0 */
var(--post-it-lavanda)     /* #e8eaf6 */
var(--post-it-menta)       /* #e0f2f1 */

/* Spacing */
var(--spacing-xs)          /* 0.25rem */
var(--spacing-sm)          /* 0.5rem */
var(--spacing-md)          /* 1rem */
var(--spacing-lg)          /* 1.5rem */
var(--spacing-xl)          /* 2rem */

/* Transitions */
var(--transition-fast)     /* 0.15s ease */
var(--transition-normal)   /* 0.3s ease */
var(--transition-smooth)   /* 0.3s cubic-bezier */
```

---

## 📱 **Responsividade**

Todos os componentes são responsivos por padrão:

```html
<!-- Grid que se adapta automaticamente -->
<div class="quadro-grid">
  <div class="post-it">Card 1</div>
  <div class="post-it">Card 2</div>
  <div class="post-it">Card 3</div>
</div>

<!-- Formulários responsivos -->
<div class="form-row">
  <!-- No mobile vira coluna automaticamente -->
  <div class="form-group">Campo 1</div>
  <div class="form-group">Campo 2</div>
</div>
```

---

## 🔧 **Como Migrar Views Existentes**

### **1. Identifique padrões repetidos**
```bash
grep -r "\.btn-giz" app/views/
grep -r "\.post-it" app/views/
```

### **2. Substitua CSS inline**
```diff
- <style>
-   .btn-giz { /* 40 linhas CSS */ }
- </style>
+ <!-- Usa o componente pronto -->
```

### **3. Use os componentes**
```diff
- <div style="display: flex; justify-content: space-between;">
+ <div class="d-flex justify-between">
```

### **4. Teste no navegador**
```bash
rails assets:precompile
```

---

## 🚀 **Para Adicionar Novos Componentes**

1. **Crie arquivo**: `app/assets/stylesheets/components/_novo-componente.scss`
2. **Importe**: Adicione `@import "components/novo-componente";` no `application.scss`
3. **Use variables**: Sempre use as CSS variables definidas em `_variables.scss`
4. **Seja responsivo**: Adicione media queries quando necessário
5. **Documente**: Adicione exemplos de uso aqui no README

---

## ✅ **Compilação de Assets**

```bash
# Desenvolvimento
rails assets:precompile RAILS_ENV=development

# Produção
rails assets:precompile RAILS_ENV=production
```

---

## 🎯 **Boas Práticas**

✅ **Use sempre as CSS variables** para manter consistência  
✅ **Prefira componentes** ao invés de CSS inline  
✅ **Teste responsividade** em diferentes telas  
✅ **Mantenha nomes semânticos** nas classes  
✅ **Documente** novos componentes criados  

---

**🎉 Enjoy your new professional CSS architecture!** 