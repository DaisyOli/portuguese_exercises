// Arquivo para inicialização do jQuery na página de resultados do quiz
document.addEventListener('turbo:load', function() {
  // Verifica se estamos na página de resultados do quiz
  if (window.location.pathname.includes('quiz_results')) {
    if (typeof jQuery !== 'undefined' && jQuery) {
      try {
        jQuery('.card-header').each(function() {
          // Qualquer inicialização específica dos cards de resultados aqui
        });
      } catch (error) {
        console.error('Erro ao processar com jQuery:', error);
      }
    } else {
      console.error('jQuery não está disponível na página de resultados!');
    }
  }
}); 