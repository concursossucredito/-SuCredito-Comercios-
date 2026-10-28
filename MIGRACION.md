# Sucrédito Comercios v2 — prueba aislada

## Seguridad del despliegue
- La rama de trabajo es `sucredito-comercios-v2`.
- El `index.html` original se conserva sin modificar.
- La nueva página de prueba es `index-v2.html`; no reemplaza todavía la página publicada.
- No cambies el origen de GitHub Pages de la web actual.

## Archivos principales
- `index-v2.html`: nueva página pública.
- `comercios-v2.css` y `comercios-v2.js`: diseño, búsqueda y filtros.
- `admin/index.html`, `admin/admin.css`, `admin/admin.js`: panel privado inicial.
- `config.js`: URL y clave pública anon de Supabase.
- `migracion-comercios-parte-1.sql` a `migracion-comercios-parte-8.sql`: carga de comercios existentes.

## Cargar los comercios existentes
1. Abrí el proyecto Supabase de Sucrédito y entrá en **SQL Editor**.
2. Abrí cada archivo SQL de esta rama y ejecutalo en orden: parte 1, 2, 3, 4, 5, 6, 7 y 8.
3. La parte 1 agrega la columna de localidad a las cuotas y prepara el índice único. Las cuotas quedan asociadas a la localidad correspondiente.
4. Al finalizar, revisá las tablas `comercios`, `comercios_categorias` y `comercios_cuotas`.

La carga se generó a partir del `DATA` y el mapa de logos del HTML actual. Incluye 55 comercios distintos, 3 categorías y las localidades/cuotas definidas en el HTML. Los logos usan las imágenes existentes en GitHub Pages.

## Prueba
La nueva página y el panel todavía no están publicados en la URL actual. Para no afectar el sitio en uso, primero cargá los datos y probá la rama antes de cambiar la configuración de Pages. El panel usa Supabase Auth y verifica que el usuario figure activo en `comercios_admins`.

## Limitaciones de esta versión
- La administración guarda directamente en las tablas de desarrollo; todavía no tiene un flujo completo de borrador, vista previa y publicación.
- Los logos se administran por URL; la subida directa de archivos desde el panel está pendiente.
- No reemplazar `index.html` ni cambiar el origen de Pages hasta validar esta versión.
