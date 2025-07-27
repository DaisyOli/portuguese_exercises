// 🎯 DASHBOARD DO ESTUDANTE - JavaScript dedicado
document.addEventListener('DOMContentLoaded', function() {
  console.log('🚀 student_dashboard.js carregado!');
  
  // Função principal de inicialização
  function initStudentDashboard() {
    console.log('🎯 Inicializando funcionalidades da dashboard...');
    
    // ✅ BOTÃO CARREGAR MAIS ATIVIDADES
    const loadMoreBtn = document.querySelector('.load-more-btn');
    if (loadMoreBtn) {
      console.log('✅ Botão load-more encontrado:', loadMoreBtn);
      
      loadMoreBtn.addEventListener('click', function() {
        console.log('🔥 Clique no botão carregar mais!');
        
        const level = this.dataset.level;
        const offset = parseInt(this.dataset.offset);
        const spinner = document.querySelector('.loading-spinner');
        
        console.log('📊 Dados:', { level, offset });
        
        // Mostrar loading
        this.style.display = 'none';
        spinner.classList.remove('d-none');
        
        // Fazer requisição
        const url = `/students/load_more?level=${level}&offset=${offset}&locale=pt`;
        console.log('🌐 URL:', url);
        
        fetch(url)
          .then(response => {
            console.log('📥 Response status:', response.status);
            return response.json();
          })
          .then(data => {
            console.log('📦 Dados recebidos:', data);
            
            // Inserir HTML
            const container = document.getElementById('activities-container');
            if (container) {
              container.insertAdjacentHTML('beforeend', data.html);
              console.log('✅ HTML inserido');
            }
            
            // Atualizar estado do botão
            spinner.classList.add('d-none');
            
            if (data.has_more) {
              this.dataset.offset = data.next_offset;
              this.innerHTML = `<i class="fas fa-plus"></i> Carregar mais (${data.remaining} restantes)`;
              this.style.display = 'inline-block';
              console.log('🔄 Offset atualizado para:', data.next_offset);
            } else {
              this.style.display = 'none';
              console.log('✅ Não há mais atividades');
            }
          })
          .catch(error => {
            console.error('💥 Erro:', error);
            spinner.classList.add('d-none');
            this.style.display = 'inline-block';
          });
      });
    } else {
      console.error('❌ Botão load-more NÃO encontrado!');
    }
    
    // ✅ BOTÃO TOGGLE ATIVIDADES COMPLETADAS
    const toggleBtn = document.querySelector('.btn-toggle-completed');
    if (toggleBtn) {
      console.log('✅ Botão toggle encontrado');
      
      toggleBtn.addEventListener('click', function() {
        const icon = this.querySelector('.toggle-icon');
        const target = document.querySelector(this.dataset.bsTarget);
        
        setTimeout(() => {
          if (target && target.classList.contains('show')) {
            icon.style.transform = 'rotate(180deg)';
          } else {
            icon.style.transform = 'rotate(0deg)';
          }
        }, 100);
      });
    }
    
    // ✅ ANIMAÇÕES DAS BARRAS DE PROGRESSO
    const progressBars = document.querySelectorAll('.progress-fill');
    progressBars.forEach(bar => {
      const width = bar.style.width || bar.getAttribute('data-width');
      bar.style.width = '0%';
      
      setTimeout(() => {
        bar.style.width = width;
      }, 500);
    });
    
    // ✅ EFEITO HOVER NOS CARDS
    const metricCards = document.querySelectorAll('.card-metrica');
    metricCards.forEach(card => {
      card.addEventListener('mouseenter', function() {
        this.style.transform = 'scale(1.05) translateY(-5px)';
      });
      
      card.addEventListener('mouseleave', function() {
        this.style.transform = 'scale(1) translateY(0)';
      });
    });
    
    console.log('🎉 Dashboard inicializada com sucesso!');
  }
  
  // Executar imediatamente se DOM já carregou
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initStudentDashboard);
  } else {
    initStudentDashboard();
  }
});

// ✅ COMPATIBILIDADE COM TURBO (Rails)
document.addEventListener('turbo:load', function() {
  console.log('🔄 Turbo load - reinicializando dashboard...');
  
  // Pequeno delay para garantir que DOM está pronto
  setTimeout(() => {
    const loadMoreBtn = document.querySelector('.load-more-btn');
    if (loadMoreBtn && !loadMoreBtn.hasAttribute('data-js-attached')) {
      loadMoreBtn.setAttribute('data-js-attached', 'true');
      console.log('🎯 Anexando event listener via Turbo...');
      
      loadMoreBtn.addEventListener('click', function() {
        console.log('🔥 Clique via Turbo!');
        
        const level = this.dataset.level;
        const offset = parseInt(this.dataset.offset);
        const spinner = document.querySelector('.loading-spinner');
        
        this.style.display = 'none';
        spinner.classList.remove('d-none');
        
        fetch(`/students/load_more?level=${level}&offset=${offset}&locale=pt`)
          .then(r => r.json())
          .then(data => {
            document.getElementById('activities-container').insertAdjacentHTML('beforeend', data.html);
            spinner.classList.add('d-none');
            
            if (data.has_more) {
              this.dataset.offset = data.next_offset;
              this.innerHTML = `<i class="fas fa-plus"></i> Carregar mais (${data.remaining} restantes)`;
              this.style.display = 'inline-block';
            } else {
              this.style.display = 'none';
            }
          })
          .catch(error => {
            console.error('Erro:', error);
            spinner.classList.add('d-none');
            this.style.display = 'inline-block';
          });
      });
    }
  }, 100);
}); 