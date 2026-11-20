import { useEffect, useState } from "react";
type Profile = {id:string;is_guest:boolean;status:string;created_at:string;email:string|null;gold:number;diamonds:number;hero_count:number;stage:string|null;nickname:string;level:number;xp:number;last_seen_at:string|null};
type Summary = {ok:boolean;stats:{accounts:number;guests:number;active_sessions:number;online_2min:number;sessions_24h:number;db_time:string};profiles:Profile[];online_note:string;edit_note:string};
export default function ServerMonitor(){
 const [data,setData]=useState<Summary|null>(null);
 const [error,setError]=useState("");
 const [busy,setBusy]=useState(false);
 const [editing,setEditing]=useState<Profile|null>(null);
 const [draft,setDraft]=useState({nickname:"",level:1,xp:0,gold:0,diamonds:0});
 const [saving,setSaving]=useState(false);
 function edit(p:Profile){setEditing(p);setDraft({nickname:p.nickname,level:p.level,xp:p.xp,gold:p.gold,diamonds:p.diamonds});}
 async function save(){
  if(!editing)return;
  if(!confirm("Подтвердить изменение профиля? Операция записывается в журнал."))return;
  setSaving(true);
  try{
   const r=await fetch("/afkgame/admin/api/operations/profiles/"+editing.id,{method:"PATCH",headers:{"Content-Type":"application/json"},body:JSON.stringify(draft)});
   if(!r.ok)throw Error(await r.text());
   setEditing(null);await refresh();
  }catch(e){alert("Не удалось сохранить: "+String(e));}finally{setSaving(false);}
 }
 async function refresh(){
  setBusy(true);
  try{const r=await fetch("/afkgame/admin/api/operations/summary",{cache:"no-store"});if(!r.ok)throw Error("HTTP "+r.status);setData(await r.json());setError("");}
  catch(e){setError(String(e));}finally{setBusy(false);}
 }
 useEffect(()=>{void refresh();const t=setInterval(()=>void refresh(),30000);return ()=>clearInterval(t)},[]);
 return <div>
  <h1>Игровой сервер и профили</h1>
  <p className="muted">Мониторинг PostgreSQL · обновление каждые 30 секунд · только чтение</p>
  <button onClick={()=>void refresh()} disabled={busy}>Обновить</button>
  {error&&<p className="warn">Ошибка: {error}</p>}
  {data&&<><div className="panel" style={{marginTop:16}}>
    <h3>Состояние базы игроков</h3>
    <p>Аккаунты: <strong>{data.stats.accounts}</strong> · Гостевые: <strong>{data.stats.guests}</strong></p>
    <p>Игроков онлайн (2 минуты): <strong>{data.stats.online_2min}</strong> · Действующие сессии: <strong>{data.stats.active_sessions}</strong></p>
    <p className="muted">{data.online_note}</p>
    <p className="muted">Время БД: {data.stats.db_time}</p>
   </div>
   <div className="panel" style={{marginTop:16}}>
    <h3>Последние 100 профилей</h3>
    <p className="warn">{data.edit_note}</p>
    <div style={{overflowX:"auto"}}>
     <table style={{width:"100%",textAlign:"left",borderSpacing:"12px 10px"}}>
      <thead><tr><th>ID</th><th>Ник</th><th>Уровень</th><th>Тип</th><th>Статус</th><th>Золото</th><th>Алмазы</th><th>Герои</th><th>Этап</th><th>Создан</th><th>Управление</th></tr></thead>
      <tbody>{data.profiles.map(p=><tr key={p.id}>
       <td title={p.id}>{p.id.slice(0,8)}…</td><td>{p.nickname}</td><td>{p.level}</td><td>{p.is_guest?"Гость":"Аккаунт"}</td><td>{p.status}</td>
       <td>{p.gold}</td><td>{p.diamonds}</td><td>{p.hero_count}</td><td>{p.stage||"—"}</td>
       <td>{new Date(p.created_at).toLocaleString("ru-RU")}</td><td><button onClick={()=>edit(p)}>Редактировать</button></td>
      </tr>)}</tbody>
     </table>
    </div>
   </div>
   {editing&&<div className="panel" style={{marginTop:16}}>
    <h3>Редактирование {editing.id.slice(0,8)}</h3>
    {(["nickname","level","xp","gold","diamonds"] as const).map(k=><label key={k} style={{display:"block",margin:"12px 0"}}>
      {({nickname:"Ник",level:"Уровень",xp:"Опыт",gold:"Золото",diamonds:"Алмазы"} as Record<string,string>)[k]}:
      <input style={{display:"block",width:"100%",maxWidth:340,padding:10,marginTop:4}} type={k==="nickname"?"text":"number"} value={draft[k]} onChange={e=>setDraft({...draft,[k]:k==="nickname"?e.target.value:Number(e.target.value)})}/>
    </label>)}
    <button disabled={saving} onClick={()=>void save()}>Сохранить изменения</button>
    <button onClick={()=>setEditing(null)} style={{marginLeft:10}}>Отмена</button>
   </div>}
   </>}
 </div>
}
