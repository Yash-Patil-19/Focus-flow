(() => {
  'use strict';
  const durations = { focus: 25, short: 5, long: 15 };
  const labels = { focus: 'TIME TO FOCUS', short: 'SHORT RESET', long: 'LONG RESET' };
  const titles = { focus: 'Start focus', short: 'Start break', long: 'Start long break' };
  const $ = (id) => document.getElementById(id);
  const timeEl = $('time'), progress = $('progress'), startBtn = $('start');
  const circumference = 2 * Math.PI * 116;
  let mode = 'focus', remaining = durations.focus * 60, running = false, deadline = 0, interval = null;
  let completed = Number(localStorage.getItem('focusflow.completed') || 0);
  let tasks = [];
  try { tasks = JSON.parse(localStorage.getItem('focusflow.tasks') || '[]'); if (!Array.isArray(tasks)) tasks = []; } catch { tasks = []; }
  const setMode = (next) => {
    stopTicker(); mode = next; remaining = durations[mode] * 60; running = false;
    document.querySelectorAll('.mode').forEach((b) => b.classList.toggle('active', b.dataset.mode === mode));
    $('session-label').textContent = labels[mode]; startBtn.textContent = titles[mode]; $('hint').textContent = mode === 'focus' ? 'Ready when you are. Take one thing off your list.' : 'A little reset can make room for a better next session.'; renderClock();
  };
  const renderClock = () => {
    const m = Math.floor(remaining / 60), s = remaining % 60;
    timeEl.textContent = `${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}`;
    progress.style.strokeDasharray = circumference;
    progress.style.strokeDashoffset = circumference * (1 - remaining / (durations[mode] * 60));
    document.title = `${timeEl.textContent} · ${mode === 'focus' ? 'Focus' : 'Break'} | FocusFlow`;
  };
  const stopTicker = () => { if (interval) clearInterval(interval); interval = null; };
  const complete = () => {
    stopTicker(); running = false; remaining = 0; renderClock();
    if (mode === 'focus') { completed += 1; localStorage.setItem('focusflow.completed', String(completed)); renderProgress(); $('hint').textContent = 'Focus session complete. Take a breath and celebrate the progress.'; setMode(completed % 4 === 0 ? 'long' : 'short'); }
    else { $('hint').textContent = 'Break finished. Ready for another focused session?'; setMode('focus'); }
    try { if ('Notification' in window && Notification.permission === 'granted') new Notification('FocusFlow', { body: 'Your timer session is complete.' }); } catch {}
  };
  const tick = () => { remaining = Math.max(0, Math.ceil((deadline - Date.now()) / 1000)); renderClock(); if (remaining <= 0) complete(); };
  const start = () => {
    if (running) { running = false; stopTicker(); startBtn.textContent = 'Resume'; $('hint').textContent = 'Timer paused. Continue when you are ready.'; return; }
    running = true; deadline = Date.now() + remaining * 1000; startBtn.textContent = 'Pause'; $('hint').textContent = mode === 'focus' ? 'One task. One session. You have got this.' : 'Step away from the screen for a moment.'; interval = setInterval(tick, 250);
  };
  const renderProgress = () => { $('completed').textContent = completed; $('dots').replaceChildren(); for(let i=0;i<Math.max(4,Math.min(8,Math.ceil(completed/4)*4));i++){const dot=document.createElement('span');if(i<completed%4 || (completed>0&&completed%4===0))dot.classList.add('done');$('dots').append(dot);} };
  const saveTasks = () => localStorage.setItem('focusflow.tasks', JSON.stringify(tasks));
  const renderTasks = () => { const ul=$('tasks'); ul.replaceChildren(); tasks.forEach((task,index)=>{const li=document.createElement('li');li.className='task-item'+(task.done?' done':'');const check=document.createElement('input');check.type='checkbox';check.checked=Boolean(task.done);check.setAttribute('aria-label','Mark task complete');check.addEventListener('change',()=>{tasks[index].done=check.checked;saveTasks();renderTasks();});const text=document.createElement('span');text.className='task-text';text.textContent=task.text;const del=document.createElement('button');del.className='delete-task';del.type='button';del.textContent='×';del.setAttribute('aria-label','Delete '+task.text);del.addEventListener('click',()=>{tasks.splice(index,1);saveTasks();renderTasks();});li.append(check,text,del);ul.append(li);}); };
  document.querySelectorAll('.mode').forEach((button)=>button.addEventListener('click',()=>setMode(button.dataset.mode)));
  startBtn.addEventListener('click',start);
  $('reset').addEventListener('click',()=>{stopTicker();running=false;remaining=durations[mode]*60;startBtn.textContent=titles[mode];renderClock();$('hint').textContent='Timer reset. Begin whenever you are ready.';});
  $('skip').addEventListener('click',()=>setMode(mode==='focus'?(completed%4===3?'long':'short'):'focus'));
  $('theme-toggle').addEventListener('click',()=>{const html=document.documentElement;const next=html.dataset.theme==='dark'?'light':'dark';html.dataset.theme=next;localStorage.setItem('focusflow.theme',next);});
  const savedTheme=localStorage.getItem('focusflow.theme');if(savedTheme==='light'||savedTheme==='dark')document.documentElement.dataset.theme=savedTheme;
  $('task-form').addEventListener('submit',(event)=>{event.preventDefault();const input=$('task-input');const value=input.value.trim();if(!value)return;if(tasks.length>=30){$('hint').textContent='Complete or remove a task before adding another.';return;}tasks.push({text:value,done:false});saveTasks();renderTasks();input.value='';input.focus();});
  $('today').textContent=new Intl.DateTimeFormat(undefined,{month:'short',day:'numeric'}).format(new Date()).toUpperCase();
  renderClock();renderProgress();renderTasks();
})();
