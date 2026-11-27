(() => {
"use strict";
const tip=document.createElement("div");
tip.id="aaa-context-tip";tip.setAttribute("role","tooltip");tip.setAttribute("popover","manual");tip.hidden=true;
document.body.append(tip);
const native=typeof tip.showPopover==="function";
const byId={
 share:["Compartir","Comparte la vista actual mediante las opciones disponibles de tu navegador."],
 edition:["Edición de datos","Fecha de actualización del conjunto de datos publicado; no garantiza que todas las fuentes estén al día."],
 loadstate:["Estado de carga","Indica qué versión del catálogo ha podido cargar esta sesión."],
 savecount:["Mi agenda","Número de eventos guardados en la agenda de esta sesión."],
 search:["Búsqueda global","Busca por nombre de evento, local, artista, promotor o fiesta, incluidos los alias disponibles."],
 genre:["Género musical","Limita la selección a la clasificación musical disponible. No garantiza todos los estilos del cartel."],
 venue:["Local","Filtra los anuncios asociados al establecimiento seleccionado."],
 zone:["Zona","Limita los resultados a la zona geográfica registrada."],
 kind:["Tipo de evento","Selecciona la categoría de evento que quieres consultar."],
 reset:["Restablecer filtros","Devuelve los controles de selección a su estado inicial."],
 pastfrom:["Inicio del archivo","Primera fecha incluida en la consulta histórica."],pastto:["Fin del archivo","Última fecha incluida en la consulta histórica."],
 applypast:["Consultar archivo","Aplica el intervalo de fechas histórico introducido."],pastweek:["Semana","Selecciona la semana de la fecha indicada."],pastmonth:["Mes","Selecciona el mes visible del calendario."],pastall:["Todo el archivo","Consulta todos los registros históricos disponibles, no todos los eventos que hayan existido."],backfuture:["Eventos futuros","Vuelve al horizonte de próximos anuncios."],
 prev:["Mes anterior","Retrocede un mes en el calendario."],next:["Mes siguiente","Avanza un mes en el calendario."],month:["Mes visible","Periodo mostrado por el calendario."],
 mode:["Marcadores del mapa","Alterna entre locales asociados a eventos seleccionados y el catálogo de establecimientos."],
 maplayer:["Capa cartográfica","Selecciona actividad, estilos musicales o señales editoriales para interpretar los colores del mapa."],
 density:["Halos de actividad","Activa o desactiva círculos visuales según el volumen de anuncios registrados; no representan aforo ni asistencia."],
 zoomIn:["Acercar","Aumenta el nivel de zoom cartográfico."],zoomOut:["Alejar","Reduce el nivel de zoom cartográfico."],center:["Centrar mapa","Recupera el centro inicial de la vista."],region:["Vista regional","Amplía el encuadre a la región configurada."],
 sort:["Orden de agenda","Cambia el criterio de ordenación; los valores sin datos no equivalen a cero."],compact:["Densidad visual","Alterna el formato de las filas de eventos."],postponed:["Estados especiales","Incluye anuncios cancelados o aplazados en los resultados."],
 listcount:["Resultados","Registros que coinciden con la selección actual, no inventario exhaustivo de la escena."],
 radarsearch:["Buscar en radar","Localiza perfiles por el texto introducido."],radartype:["Tipo de perfil","Limita el radar a la entidad elegida."],
 impactfrom:["Inicio del análisis","Primera fecha del periodo de impacto."],impactto:["Fin del análisis","Última fecha del periodo de impacto."],impactapply:["Aplicar intervalo","Actualiza el análisis con las fechas seleccionadas."],impactyesterday:["Ayer","Consulta el día anterior."],impactweek:["Semana","Consulta el periodo semanal."],impactall:["Histórico","Consulta el historial disponible."],impactgroup:["Agrupar impacto","Cambia la dimensión de agrupación de los resultados."],impactsearch:["Buscar impacto","Filtra las entidades o registros por texto."],impactfilter:["Filtrar impacto","Limita los resultados según el criterio seleccionado."],impactsort:["Ordenar impacto","Cambia la ordenación de los registros del análisis."],
 method:["Metodología AAA","Consulta las definiciones, fuentes y límites de los indicadores."],methodintel:["Metodología HYPE","Consulta la construcción y límites del modelo editorial."],closedetail:["Cerrar ficha","Regresa a la vista anterior."],expandposter:["Ampliar cartel","Abre la imagen disponible del evento."],
 "aaa-radio-enable":["Radio AAA","Activa el reproductor externo de música; puede conectar con Spotify."],"aaa-radio-next":["Siguiente","Avanza a otra selección musical."],"aaa-radio-list":["Lista","Abre la lista musical disponible."],"aaa-radio-toggle":["Vídeo","Alterna la vista del reproductor de vídeo externo."],"aaa-radio-off":["Desactivar radio","Cierra el reproductor y libera sus recursos."],"aaa-radio-status":["Estado de radio","Estado comunicado por el reproductor."],
 refresh:["Actualizar operaciones","Consulta de nuevo los datos de despliegues y catálogo."],fresh:["Última comprobación","Antigüedad de la última consulta disponible."],runState:["Estado del despliegue","Estado publicado por GitHub Actions para la ejecución mostrada."],runTitle:["Ejecución","Flujo de publicación identificado en GitHub Actions."],progress:["Progreso","Estimación basada en los pasos observables; no es una garantía de finalización."],elapsed:["Tiempo transcurrido","Duración observada de la ejecución."],eta:["Tiempo restante estimado","Estimación histórica, no plazo garantizado."],runLink:["Ver ejecución","Abre el registro de GitHub Actions."],release:["Versión publicada","Identificador del artefacto de despliegue disponible."],worldNext:["Próxima investigación mundial","Horario previsto; no confirma que el cron se haya ejecutado."],madridNext:["Próxima investigación Madrid","Horario previsto; no confirma una ejecución real."],worldResearch:["Investigación mundial","Estado conocido del seguimiento internacional."],madridResearch:["Investigación Madrid","Estado conocido del seguimiento local."],filter:["Filtrar cola","Busca registros de investigación por el texto introducido."],queueCount:["Cola de investigación","Número de registros visibles según la selección."],unlinked:["Perfiles sin vínculos","Entidades pendientes de relacionar con eventos explícitos; ausencia de relación no prueba ausencia de actividad."],history:["Historial de despliegues","Ejecuciones recientes observadas en GitHub Actions."],
 email:["Correo de acceso","Dirección que se usa para verificar la identidad. No la compartas fuera de la pantalla de acceso."],guestAdult:["Mayoría de edad","Declaración de tener al menos 18 años; no equivale a verificación documental."],notice:["Aviso de privacidad","Confirma haber recibido la información; no implica aceptar personalización."],adult:["Mayoría de edad","Declaración requerida por la política de acceso."],terms:["Condiciones de uso","Aceptación de las condiciones aplicables al servicio."],profileNotice:["Información de privacidad","Constancia de recepción del aviso, separada del consentimiento opcional."],display:["Nombre visible","Alias o nombre que quieres mostrar en tu perfil."],country:["País","Preferencia territorial aportada voluntariamente."],region:["Región","Preferencia geográfica de perfil."],city:["Ciudad","Ciudad de interés para personalizar el catálogo."],locale:["Idioma","Preferencia lingüística del perfil."],radius:["Radio","Distancia de búsqueda preferida, en kilómetros; no requiere ubicación precisa."],genres:["Géneros favoritos","Preferencias declaradas por ti; no se importan de Spotify."],eventTypes:["Tipos de evento","Selecciona categorías de interés."],personalize:["Personalización opcional","Autoriza recomendaciones a partir de tus preferencias declaradas. Puedes retirarla."],saveProfile:["Guardar perfil","Registra las decisiones y datos seleccionados, sujetos a la política vigente."],logout:["Cerrar sesión","Finaliza la sesión de AAA en este navegador."],artistSearch:["Buscar artista","Busca perfiles del catálogo para añadir favoritos."],musicType:["Tipo de preferencia","Clasifica la preferencia musical que introduces manualmente."],musicTitle:["Título","Nombre de la preferencia aportada."],musicArtist:["Artista","Artista asociado, si lo conoces."],withdraw:["Retirar personalización","Retira el consentimiento de recomendaciones sin eliminar el acceso básico."],export:["Solicitar exportación","Registra una solicitud de derechos; no es una descarga inmediata."],delete:["Solicitar supresión","Inicia una solicitud de eliminación, sujeta a revisión y obligaciones aplicables."],rightKind:["Derecho de privacidad","Selecciona el tipo de solicitud."],requestRight:["Enviar solicitud","Registra la petición de privacidad."],enroll:["Configurar MFA","Inicia la configuración del autenticador de doble factor."],mfaCode:["Código temporal","Introduce el código del autenticador únicamente en el formulario seguro."],verifyMfa:["Verificar MFA","Comprueba el código de un solo uso."],reloadUsers:["Actualizar usuarios","Consulta las cuentas autorizadas para el administrador con MFA."],accessInfo:["Estado de acceso","Autorización asignada por el servidor; iniciar sesión no concede permisos administrativos."],myModules:["Módulos AAA","Servicios disponibles según plan, acceso y consentimiento."],myIdentities:["Conexiones","Proveedores de identidad vinculados; no implica importar su contenido."],suggestions:["AAA Personal+","Sugerencias basadas en coincidencias con las preferencias y favoritos declarados."],privacyRequests:["Solicitudes RGPD","Historial de solicitudes y su estado; el registro no implica que estén resueltas."],consentHistory:["Historial de consentimiento","Registro de decisiones de personalización."],fixtureEmail:["Identidad de prueba","Cuenta sintética del entorno de pruebas."],fixturePassword:["Contraseña de prueba","Credencial privada de una cuenta sintética."]
};
const views={explore:"Explorar el catálogo de anuncios y aplicar filtros.",map:"Ver la distribución geográfica de la selección.",intel:"Consultar indicadores y metodología de la inteligencia AAA.",saved:"Consultar los eventos guardados.",directory:"Navegar por locales, artistas, promotores y fiestas.",radar:"Descubrir perfiles y actividad del catálogo.",styles:"Explorar clasificaciones musicales disponibles.",archive:"Consultar anuncios anteriores a la fecha actual.",impact:"Analizar repercusión histórica cuando existen señales suficientes.",foryou:"Ver sugerencias según la configuración de la experiencia."};
const types={all:"Busca en todas las entidades disponibles.",events:"Busca anuncios de eventos.",venues:"Busca establecimientos y espacios.",promoters:"Busca organizaciones promotoras.",series:"Busca marcas de fiesta o ciclos.",artists:"Busca artistas y sus perfiles."};
const classInfo=[
 [".god-pass","GOD PASS","Emblema personal del fundador; no acredita acceso, calidad de eventos ni aprobación divina."],
 [".brand","AAA","Access All Areas · identidad de la plataforma de descubrimiento nocturno."],
 [".signature","Firma","Firma personal del fundador de AAA."],
 [".sig.hype","HYPE","Estimación editorial AAA de 0 a 100: experiencia, demanda, impacto social, trascendencia y evolución. No es una medición directa de demanda."],
 [".sig.impact","IMPACT","Repercusión posterior basada en señales disponibles; puede no existir evidencia suficiente para calcularla."],
 [".sig.data","Completitud de datos","Porcentaje de campos disponibles (fuente, entradas, cartel, estilo, precio y hora). No equivale a fiabilidad."],
 [".sig.demand","Señal de demanda","Información publicada sobre disponibilidad o demanda; no acredita asistencia ni ventas."],
 [".sig","Señal del evento","Indicador contextual del catálogo. N/D significa que no hay información suficiente."],
 [".scorevalue","Puntuación del radar","Valor HYPE o IMPACT según la vista activa; un guion representa ausencia de puntuación."],
 [".ranknum","Posición","Posición dentro del ranking mostrado y su intervalo de selección."],
 [".aaa-signature-seal","Sello editorial AAA","Distinción editorial independiente de HYPE e IMPACT."],
 [".eventkind","Tipo de evento","Categoría registrada en el anuncio."],
 [".eventmeta","Información del anuncio","Fecha, horario, establecimiento o promotor registrado. Confirma los detalles con la fuente."],
 [".tag","Etiqueta","Atributo registrado del evento o perfil; puede ser parcial o estar pendiente de revisión."],
 [".cover,.posterlarge","Imagen del evento","Material visual asociado al anuncio; puede no estar disponible."],
 [".eventrow,.open-event","Evento","Abre su ficha para consultar el cartel, fecha, local, fuentes y señales disponibles."],
 [".entitycard,.cataloguecard","Perfil del catálogo","Consulta la identidad de la entidad y los anuncios vinculados. La cobertura puede ser incompleta."],
 [".pin","Marcador","Establecimiento en el mapa; el número indica anuncios asociados, no aforo."],
 [".mapbubble","Halo","Indicador visual del volumen de actividad registrada, no área real de influencia."],
 [".zonerow,.zonebar","Actividad territorial","Distribución de registros por zona; depende de la cobertura y filtros vigentes."],
 [".rankrow","Radar","Evento situado según las puntuaciones disponibles en el intervalo seleccionado."],
 [".bartrack,.barfill","Barra de indicador","Representación visual de la métrica asociada; consulta el valor y su metodología."],
 [".stat","Indicador","Valor calculado para la sección activa, condicionado por los registros disponibles."],
 [".notice,.mapnote","Nota de cobertura","Advertencia sobre el alcance y limitaciones de la información disponible."],
 [".edition","Edición","Referencia temporal del catálogo cargado."],
 [".cal","Calendario","El número de cada día indica anuncios localizados, no aforo ni disponibilidad."],
 [".map","Mapa","Cartografía de establecimientos. Las ubicaciones pueden ser aproximadas."],
 [".legendstrip,.maplegend","Leyenda","Explica el significado de colores, símbolos y señales de la vista."],
 [".weekends","Horizonte de fines de semana","Selecciona un periodo de próximos anuncios."],
 [".hype-section","Radar editorial","Consulta los eventos según sus señales y puntuaciones disponibles."],
 [".events-section","Agenda","Anuncios que coinciden con el horizonte y filtros elegidos."],
 [".calendar-section","Calendario","Navega por fechas y actividad registrada."],
 [".map-section","Cartografía","Distribución geográfica de la actividad nocturna registrada."],
 [".quality > div,.detailstats > div,.kpi,.insightrow","Indicador","Métrica calculada a partir de la información disponible; no presupone cobertura total."],
 [".sectionhead","Sección","Controles y contexto del bloque mostrado."]
];
const metricRules=[
 [/cobertura cuantitativa/i,"Proporción de componentes con datos cuantitativos observados, no probabilidad de acierto."],
 [/cobertura|% base/i,"Proporción de señales disponibles para el cálculo; no es confianza estadística."],
 [/completitud|calidad.*dato/i,"Campos informativos disponibles; no certifica la exactitud de los registros."],
 [/hype/i,"Valoración editorial de anticipación de AAA; no es aforo ni ventas medidas."],
 [/impact/i,"Repercusión histórica cuando existen datos suficientes; no equivale a popularidad total."],
 [/precio|entradas/i,"Información publicada sobre precio o venta; comprueba la fuente antes de comprar."],
 [/locales|venues/i,"Establecimientos registrados que cumplen el criterio actual; cobertura no exhaustiva."],
 [/artistas/i,"Perfiles de artistas registrados o relacionados; los créditos pueden ser parciales."],
 [/promotores/i,"Organizaciones promotoras registradas o relacionadas con el catálogo."],
 [/eventos|anuncios/i,"Número de registros según los filtros y periodo de la vista; no es un censo completo."],
 [/fuentes/i,"Fuentes registradas o consultadas; no confirma individualmente cada dato."],
 [/pendient|sin enlazar|sin vínculo/i,"Registros que requieren investigación o enlace adicional."],
 [/demanda/i,"Señales sobre disponibilidad o interés publicadas, no volumen de asistencia."],
 [/experiencia|trascendencia|evolución|impacto social/i,"Componente ponderado de la valoración editorial, con base neutral cuando falta evidencia."]
];
const tidy=s=>String(s||"").replace(/\s+/g," ").trim().slice(0,300);
const ownText=e=>tidy(e?.textContent);
const label=e=>tidy(e.getAttribute("aria-label")||e.querySelector(":scope > strong,:scope > b,:scope > h2,:scope > h3")?.textContent||e.getAttribute("placeholder")||ownText(e));
function metric(e){const l=tidy(e.querySelector("small,.micro,span,h3,h2")?.textContent||"Indicador");const v=tidy(e.querySelector("b,strong,.value")?.textContent||"");return {title:l,body:metricRules.find(([re])=>re.test(l))?.[1]||"Indicador de esta vista calculado a partir de los datos disponibles.",value:v};}
const selector='[data-tooltip],[title],[data-aaa-native-title],button,a[href],input:not([type=hidden]),select,textarea,summary,[role=button],[data-view],[data-entitytype],.god-pass,.brand,.signature,.sig,.scorevalue,.ranknum,.aaa-signature-seal,.eventkind,.eventmeta,.tag,.cover,.posterlarge,.eventrow,.entitycard,.cataloguecard,.pin,.mapbubble,.zonerow,.zonebar,.rankrow,.bartrack,.barfill,.stat,.notice,.mapnote,.edition,.cal,.map,.legendstrip,.maplegend,.weekends,.hype-section,.events-section,.calendar-section,.map-section,.quality > div,.detailstats > div,.kpi,.insightrow,.sectionhead,td,th,dt,dd,section[id],article.panel,.metric,.panel,.chip,[data-aaa-tooltip-focus]';
const metricSelector=".kpi,.quality > div,.detailstats > div,.insightrow,.metric";
function explain(e){
 if(e===tip||tip.contains(e)||e.matches("input[type=password]"))return null;
 const explicit=e.getAttribute("data-tooltip");
 const title=e.getAttribute("data-aaa-native-title")||e.getAttribute("title");
 const id=e.id==="region"&&e.matches("button")?["Vista regional","Amplía el encuadre a la región configurada."]:byId[e.id];
 if(explicit)return {title:label(e)||"Contexto AAA",body:explicit};
 if(e.matches(".pin")&&title)return {title:label(e)||"Local",body:title+" · El número indica anuncios registrados, no aforo."};
 if(e.matches(".sig")&&title){const rule=classInfo.find(([s])=>e.matches(s));return {title:rule?.[1]||"Señal",body:title+" "+(rule?.[2]||""),value:ownText(e)};}
 if(e.matches(metricSelector))return metric(e);
 if(id)return {title:id[0],body:id[1],value:e.matches("input,select,textarea,button,a")?"":ownText(e)};
 if(e.dataset.view&&views[e.dataset.view])return {title:label(e),body:views[e.dataset.view]};
 if(e.dataset.entitytype&&types[e.dataset.entitytype])return {title:label(e),body:types[e.dataset.entitytype]};
 if(e.dataset.scope!==undefined)return {title:label(e),body:"Cambia el intervalo temporal de los resultados; el catálogo puede tener cobertura parcial."};
 if(e.dataset.event!==undefined)return {title:label(e)||"Evento",body:"Abre la ficha del anuncio para consultar sus detalles y fuentes."};
 if(e.dataset.save!==undefined)return {title:label(e)||"Guardar evento",body:"Añade o retira este evento de tu agenda."};
 if(e.dataset.follow!==undefined)return {title:label(e)||"Seguir perfil",body:"Añade o retira la entidad de tus seguimientos."};
 if(e.dataset.artist!==undefined||e.dataset.promoter!==undefined||e.dataset.series!==undefined||e.dataset.venueinfo!==undefined)return {title:label(e)||"Perfil",body:"Abre la ficha de la entidad y sus relaciones disponibles."};
 if(e.dataset.locate!==undefined||e.dataset.club!==undefined)return {title:label(e)||"Localizar",body:"Localiza o selecciona el establecimiento en el mapa."};
 if(title)return {title:label(e)||"Información",body:title};
 if(e.matches("a[href]")){const href=e.getAttribute("href")||"";const l=label(e)||"Enlace";return {title:l,body:href.includes("account.html")?"Accede al portal de identidad y preferencias.":href.includes("operations.html")?"Consulta el estado de publicación e investigación.":/entradas/i.test(l)?"Abre el proveedor externo de entradas. Comprueba disponibilidad y precio.":href.startsWith("http")?"Abre una fuente o servicio externo.": "Abre la página o sección enlazada."};}
 if(e.matches("td,th,dt,dd")){const th=e.closest("table")?.querySelectorAll("thead th");const l=e.matches("td")?tidy(th?.[e.cellIndex]?.textContent):ownText(e);const v=ownText(e);return v?{title:l||"Dato de tabla",body:metricRules.find(([re])=>re.test(l))?.[1]||"Valor registrado en la fila y columna de esta tabla.",value:e.matches("td,dd")?v:""}:null;}
 const rule=classInfo.find(([s])=>e.matches(s));if(rule)return {title:rule[1],body:rule[2],value:e.matches(".tag,.eventmeta,.scorevalue,.ranknum,.stat")?ownText(e):""};
 if(e.matches("input,select,textarea")){const l=tidy(e.labels?.[0]?.textContent||e.getAttribute("aria-label")||e.getAttribute("placeholder"));return l?{title:l,body:e.matches("select")?"Selecciona una de las opciones disponibles.":e.matches("[type=checkbox],[type=radio]")?"Activa o selecciona esta opción.":"Introduce el valor solicitado."}:null;}
 if(e.matches("button,summary,[role=button]")){const l=label(e);return l?{title:l,body:e.disabled?"Acción no disponible actualmente.":e.hasAttribute("aria-pressed")?"Alterna esta opción; el estado actual se indica en el control.":"Ejecuta la acción indicada en este control."}:null;}
 if(e.matches("section[id],article.panel,.panel,.chip")){const l=tidy(e.querySelector("h2,h3,h4,.eyebrow")?.textContent||e.getAttribute("aria-label"));return l?{title:l,body:metricRules.find(([re])=>re.test(l))?.[1]||"Bloque de información y acciones relacionadas con esta sección."}:null;}
 return null;
}
let active=null,enterTimer=0,leaveTimer=0,blocked=null,raf=0,hoverTip=false;
function target(node){if(!(node instanceof Element))return null;let e=node.closest(selector);while(e&&e!==document.body){if(explain(e))return e;e=e.parentElement?.closest(selector);}return null;}
function preserveTitle(e){if(e.hasAttribute("title")&&!e.hasAttribute("data-aaa-native-title")){e.setAttribute("data-aaa-native-title",e.getAttribute("title"));e.removeAttribute("title");}}
function content(cls,value){const n=document.createElement("span");n.className=cls;n.textContent=value;tip.append(n);}
function position(){if(!active||!active.isConnected||!active.getClientRects().length){hide();return;}const a=active.getBoundingClientRect();const vw=document.documentElement.clientWidth,vh=window.innerHeight;const w=tip.offsetWidth,h=tip.offsetHeight,p=10,gap=9;let x=a.left+a.width/2-w/2;let y=a.bottom+gap;if(y+h>vh-p&&a.top-h-gap>=p)y=a.top-h-gap;if(y+h>vh-p)y=Math.max(p,Math.min(vh-h-p,a.top));x=Math.max(p,Math.min(vw-w-p,x));tip.style.left=Math.round(x)+"px";tip.style.top=Math.round(y)+"px";}
function show(e){clearTimeout(leaveTimer);if(e===blocked||!e?.isConnected)return;const info=explain(e);if(!info)return;if(active!==e){hide();active=e;preserveTitle(e);const prior=e.getAttribute("aria-describedby")||"";e.setAttribute("aria-describedby",(prior+" "+tip.id).trim());tip.replaceChildren();content("aaa-tip-kicker","AAA · CONTEXTO");content("aaa-tip-title",info.title);content("aaa-tip-body",info.body);if(info.value&&info.value!==info.title)content("aaa-tip-value",info.value);const dialog=e.closest("dialog[open]");const host=dialog||document.body;if(tip.parentNode!==host)host.append(tip);tip.hidden=false;if(native){try{tip.showPopover()}catch{}} }position();}
function hide(){clearTimeout(enterTimer);clearTimeout(leaveTimer);if(active){const v=(active.getAttribute("aria-describedby")||"").split(/\s+/).filter(x=>x&&x!==tip.id);v.length?active.setAttribute("aria-describedby",v.join(" ")):active.removeAttribute("aria-describedby");}active=null;hoverTip=false;if(native){try{tip.hidePopover()}catch{}}tip.hidden=true;}
function schedule(e,delay=250){clearTimeout(enterTimer);clearTimeout(leaveTimer);if(e!==active&&active)hide();enterTimer=setTimeout(()=>show(e),delay);}
function deferHide(){clearTimeout(enterTimer);clearTimeout(leaveTimer);leaveTimer=setTimeout(()=>{if(!hoverTip&&document.activeElement!==active)hide();},170);}
document.addEventListener("pointerover",ev=>{if(ev.pointerType==="touch"||tip.contains(ev.target))return;const e=target(ev.target);if(!e||e===target(ev.relatedTarget))return;if(blocked&&blocked!==e)blocked=null;preserveTitle(e);schedule(e);});
document.addEventListener("pointerout",ev=>{if(ev.pointerType==="touch"||tip.contains(ev.target))return;const e=target(ev.target);if(!e||e===target(ev.relatedTarget))return;if(blocked===e)blocked=null;deferHide();});
tip.addEventListener("pointerenter",()=>{hoverTip=true;clearTimeout(leaveTimer);});
tip.addEventListener("pointerleave",()=>{hoverTip=false;deferHide();});
document.addEventListener("focusin",ev=>{const e=target(ev.target);if(e){blocked=null;schedule(e,120);}else hide();});
document.addEventListener("focusout",ev=>{if(target(ev.target))deferHide();});
document.addEventListener("keydown",ev=>{if(ev.key==="Escape"&&active){blocked=active;hide();}});
document.addEventListener("pointerdown",ev=>{if(!tip.contains(ev.target)&&active&&target(ev.target)!==active)hide();});
document.addEventListener("pointerup",ev=>{if(ev.pointerType!=="touch"||tip.contains(ev.target))return;const e=target(ev.target);if(e&&!e.closest("button,a,input,select,textarea,[role=button]")){active===e?hide():show(e);}});
function reposition(){if(!active)return;cancelAnimationFrame(raf);raf=requestAnimationFrame(position);}
document.addEventListener("scroll",reposition,true);window.addEventListener("resize",reposition);window.visualViewport?.addEventListener("resize",reposition);
document.addEventListener("close",hide,true);document.addEventListener("visibilitychange",()=>{if(document.hidden)hide();});
/* Only meaningful standalone data gets an extra keyboard stop. Interactive descendants keep native focus. */
function decorate(root){if(!(root instanceof Element))return;const sel=".kpi,.quality > div,.detailstats > div,.scorevalue,.sig,.stat,.metric,.insightrow";const items=[...(root.matches(sel)?[root]:[]),...root.querySelectorAll(sel)];for(const e of items){if(!e.closest("button,a,input,select,textarea,[role=button]")&&!e.querySelector("button,a,input,select,textarea")&&!e.hasAttribute("tabindex")){e.tabIndex=0;e.setAttribute("data-aaa-tooltip-focus","");}}}
decorate(document.body);
new MutationObserver(records=>{for(const r of records)for(const n of r.addedNodes)if(n instanceof Element&&n!==tip&&!tip.contains(n))decorate(n);if(active&&!active.isConnected)hide();}).observe(document.body,{childList:true,subtree:true});
})();