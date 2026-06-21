function initTeacherOnboardingTour() {
  if (typeof Shepherd === 'undefined') return
  const root = document.getElementById('teacher-dashboard-root')
  if (!root) return

  const userId = root.dataset.userId
  const storageKey = `practicebr_tour_teacher_done_${userId}`
  if (localStorage.getItem(storageKey)) return

  const tour = new Shepherd.Tour({
    useModalOverlay: true,
    defaultStepOptions: {
      cancelIcon: { enabled: true },
      scrollTo: { behavior: 'smooth', block: 'center' }
    }
  })

  tour.addStep({
    id: 'welcome',
    text: '<strong>Seja bem-vinda ao seu painel de professora! 👩‍🏫</strong><br><br>Vamos conhecer as principais funcionalidades.',
    buttons: [
      { text: 'Pular', action: () => tour.cancel(), classes: 'shepherd-button-secondary' },
      { text: 'Começar →', action: () => tour.next() }
    ]
  })

  const steps = [
    { id: 'metrics',        el: '#tour-teacher-metrics',  on: 'bottom', text: 'Aqui você acompanha o desempenho da turma: atividades criadas, alunos ativos, tentativas e origem das atividades.' },
    { id: 'students',       el: '#tour-teacher-students', on: 'top',    text: 'Seus alunos mais recentes aparecem aqui. Clique em um aluno para ver o histórico completo e deixar feedback.' },
    { id: 'nova-atividade', el: '#tour-nova-atividade',   on: 'bottom', text: 'Crie atividades manualmente com este botão. Você define título, descrição, nível CEFR e os exercícios.' },
    { id: 'convidar',       el: '#tour-convidar',         on: 'bottom', text: 'Convide alunos por email. Eles recebem um link e já entram direto na sua turma.' },
    { id: 'avatar',         el: '#tour-avatar',           on: 'bottom', text: 'Seu menu fica aqui — configurações de conta e opção de sair.' }
  ]

  const visibleSteps = steps.filter(s => document.querySelector(s.el))
  visibleSteps.forEach((s, i) => {
    const isLast = i === visibleSteps.length - 1
    tour.addStep({
      id: s.id,
      attachTo: { element: s.el, on: s.on },
      text: s.text,
      buttons: [{ text: isLast ? 'Concluir ✓' : 'Próximo →', action: () => isLast ? tour.complete() : tour.next() }]
    })
  })

  tour.on('complete', () => localStorage.setItem(storageKey, '1'))
  tour.on('cancel',   () => localStorage.setItem(storageKey, '1'))
  tour.start()
}

function initActivityShowTour() {
  if (typeof Shepherd === 'undefined') return
  const root = document.getElementById('activity-show-root')
  if (!root) return

  const userId = root.dataset.userId
  const storageKey = `practicebr_tour_activity_done_${userId}`
  if (localStorage.getItem(storageKey)) return

  const tour = new Shepherd.Tour({
    useModalOverlay: true,
    defaultStepOptions: {
      cancelIcon: { enabled: true },
      scrollTo: { behavior: 'smooth', block: 'center' }
    }
  })

  tour.addStep({
    id: 'welcome',
    text: '<strong>Esta é a página da sua atividade 📝</strong><br><br>É aqui que você monta tudo — exercícios, materiais e uma prévia para os alunos.',
    buttons: [
      { text: 'Pular', action: () => tour.cancel(), classes: 'shepherd-button-secondary' },
      { text: 'Começar →', action: () => tour.next() }
    ]
  })

  const steps = [
    { id: 'panel',     el: '#tour-add-content-panel',    on: 'top',    text: 'Este é o painel de conteúdo. Tudo o que você pode adicionar aparece aqui, organizado em dois grupos.' },
    { id: 'material',  el: '#tour-study-material-group', on: 'bottom', text: 'No grupo <strong>Material de estudo</strong>, adicione enunciado, imagem, vídeo ou texto de apoio para contextualizar os exercícios.' },
    { id: 'exercises', el: '#tour-exercises-group',      on: 'bottom', text: 'No grupo <strong>Exercícios</strong>, escolha o tipo e clique para ver o formulário aparecer. Após criar, o exercício lista acima automaticamente.' },
    { id: 'preview',   el: '#tour-resolve-quiz',         on: 'top',    text: 'Quando terminar, clique aqui para ver a atividade exatamente como o aluno vai ver — antes de publicar.' }
  ]

  const visibleSteps = steps.filter(s => document.querySelector(s.el))
  visibleSteps.forEach((s, i) => {
    const isLast = i === visibleSteps.length - 1
    tour.addStep({
      id: s.id,
      attachTo: { element: s.el, on: s.on },
      text: s.text,
      buttons: [{ text: isLast ? 'Concluir ✓' : 'Próximo →', action: () => isLast ? tour.complete() : tour.next() }]
    })
  })

  tour.on('complete', () => localStorage.setItem(storageKey, '1'))
  tour.on('cancel',   () => localStorage.setItem(storageKey, '1'))
  tour.start()
}

document.addEventListener('DOMContentLoaded', function() {
  initTeacherOnboardingTour()
  initActivityShowTour()
})
