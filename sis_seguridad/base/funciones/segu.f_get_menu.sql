--------------- SQL ---------------

CREATE OR REPLACE FUNCTION segu.f_get_menu (
  p_administrador integer,
  p_id_usuario integer,
  p_id_gui integer = NULL::integer,
  pa_id_sistema integer [] = NULL::integer[],
  p_mobile integer = 0
)
RETURNS jsonb AS
$body$
/**************************************************************************
 FUNCION:       segu.f_get_menu
 DESCRIPCION:   Recursi function to get menu options 
 AUTOR:         RAC - KPLIAN        
 FECHA:         10/04/2020
 COMENTARIOS:    
***************************************************************************

 ISSUE            FECHA:            AUTOR               DESCRIPCION  
 #128          10/04/2020           RAC            CREACION
***************************************************************************/
DECLARE
    v_registros         RECORD;
    v_resp_json         JSONB;
    v_resp				VARCHAR; 
    v_nombre_funcion    VARCHAR;   
BEGIN
   
   v_resp_json := '[]'::JSONB;
   IF p_mobile = 0 THEN  --if it's no to mobile interface
       IF p_administrador = 1 THEN --if the user is an administrator      
           FOR v_registros IN (
                               SELECT
                                    g.nombre as "text",                                    
                                    g.clase_vista as component,
                                    CASE
                                    WHEN (g.ruta_archivo is null or g.ruta_archivo='')THEN
                                         'carpeta'::varchar
                                    ELSE
                                        'hoja'::varchar
                                    END AS "type",
                                    g.icono AS icon,                                    
                                    '[]'::jsonb as childrens
                              FROM segu.tgui g
                              INNER JOIN segu.testructura_gui eg  ON g.id_gui=eg.id_gui  AND eg.estado_reg = 'activo'                                 
                              WHERE     g.visible='si'
                                    AND g.estado_reg = 'activo'                                
                                    AND eg.fk_id_gui = p_id_gui
                                    AND (pa_id_sistema IS NULL OR g.id_subsistema = ANY(pa_id_sistema))
                              ORDER BY g.orden_logico,eg.fk_id_gui) LOOP
                     
                IF v_registros.tipo != 'hoja' THEN 
                   v_registros.childrens = segu.f_get_menu(p_administrador, p_id_usuario, v_registros.id_gui, pa_id_sistema);
                END IF;  
                
                v_resp_json = v_resp_json || row_to_json(v_registros)::jsonb;        
                               
          END LOOP;
          
       ELSE  --if the user is not an administrator
          FOR v_registros IN (
                               SELECT
                                    g.nombre as "text",                                    
                                    g.clase_vista as component,
                                    CASE
                                    WHEN (g.ruta_archivo is null or g.ruta_archivo='')THEN
                                         'carpeta'::varchar
                                    ELSE
                                        'hoja'::varchar
                                    END AS "type",
                                    g.icono AS icon, 
                                    '[]'::jsonb as childrens
                              FROM segu.tgui g
                              INNER JOIN segu.testructura_gui eg  ON g.id_gui=eg.id_gui  AND eg.estado_reg = 'activo'
                              INNER JOIN segu.tgui padre ON     padre.id_gui = eg.fk_id_gui 
                                                            AND g.id_gui=eg.id_gui
                                                            AND g.estado_reg='activo'
                                                            AND eg.estado_reg='activo'
                              INNER JOIN segu.tgui_rol gr ON     gr.id_gui=g.id_gui
                                                             AND gr.estado_reg='activo'
                              INNER JOIN segu.trol r ON     r.id_rol=gr.id_rol
                                                        AND r.estado_reg='activo'
                              INNER JOIN segu.tusuario_rol ur  ON     ur.id_rol=r.id_rol
                                                                  AND ur.estado_reg='activo'
                              INNER JOIN segu.tusuario u  ON     u.id_usuario=ur.id_usuario
                                                             AND u.estado_reg='activo'                                
                              
                              WHERE     g.visible='si'
                                    AND g.estado_reg = 'activo'                                
                                    AND eg.fk_id_gui = p_id_gui
                                    AND u.id_usuario = p_id_usuario
                                    AND (pa_id_sistema IS NULL OR g.id_subsistema = ANY(pa_id_sistema))
                              GROUP BY 
                                 g.nombre,
                                 g.clase_vista,
                                 g.ruta_archivo,
                                 g.icono,                                 
                                 childrens
                              ORDER BY g.orden_logico,eg.fk_id_gui) LOOP
                     
                IF v_registros.tipo != 'hoja' THEN 
                   v_registros.childrens = segu.f_get_menu(p_administrador, p_id_usuario, v_registros.id_gui, pa_id_sistema);            
                END IF;  
                
                v_resp_json = v_resp_json || row_to_json(v_registros)::jsonb;        
                               
          END LOOP;
       
       END IF; 
   ELSE  -- it's for mobile interface
           
       --for mobile the response  is plane (it is not a tree)
       IF p_administrador = 1 THEN --if the user is an administrator  
            FOR v_registros IN (            
                                SELECT 
                                    g.nombre as "text",                                    
                                    g.clase_vista as component,
                                    CASE
                                    WHEN (g.ruta_archivo is null or g.ruta_archivo='')THEN
                                         'carpeta'::varchar
                                    ELSE
                                        'hoja'::varchar
                                    END AS "type",
                                    g.icono AS icon, 
                                    '[]'::jsonb as childrens
                                FROM segu.tgui g
                                INNER JOIN segu.testructura_gui eg ON g.id_gui = eg.id_gui AND  eg.estado_reg = 'activo'          
                                WHERE     g.estado_reg = 'activo'
                                     AND  sw_mobile = 'si'
                                     AND (pa_id_sistema IS NULL OR g.id_subsistema = ANY(pa_id_sistema))
                                ORDER BY g.orden_logico,g.nombre) LOOP
             
                v_resp_json = v_resp_json || row_to_json(v_registros)::jsonb;            
            
            END LOOP;                     
              
       
       ELSE   --if the user is not an administrator
           FOR v_registros IN (            
                                SELECT 
                                    g.nombre as "text",                                    
				    g.clase_vista as component,
				    CASE
				    WHEN (g.ruta_archivo is null or g.ruta_archivo='')THEN
					 'carpeta'::varchar
				    ELSE
					'hoja'::varchar
				    END AS "type",
				    g.icono AS icon, 
                                    '[]'::jsonb as childrens
                                FROM segu.tgui g
                                     INNER JOIN segu.testructura_gui eg ON g.id_gui = eg.id_gui AND eg.estado_reg =  'activo'
                                     INNER JOIN segu.tgui_rol gr ON gr.id_gui =  g.id_gui AND gr.estado_reg = 'activo'
                                     INNER JOIN segu.trol r ON r.id_rol = gr.id_rol AND r.estado_reg = 'activo'
                                     INNER JOIN segu.tusuario_rol ur on ur.id_rol = r.id_rol and ur.estado_reg =  'activo'
                                WHERE g.estado_reg = 'activo' 
                                  AND sw_mobile = 'si' 
                                  AND ur.id_usuario = p_id_usuario
                                  AND (pa_id_sistema IS NULL OR g.id_subsistema = ANY (pa_id_sistema))
                                GROUP BY   
                                   g.nombre,                                   
                                   g.ruta_archivo,
                                   g.clase_vista,
                                   g.icono,                                   
                                   childrens
                                ORDER BY g.orden_logico,
                                         g.nombre) LOOP
             
                v_resp_json = v_resp_json || row_to_json(v_registros)::JSONB;            
            
            END LOOP; 
       
       END IF;
       
      
   
   END IF;
  
 RETURN  v_resp_json;
 
 EXCEPTION

  	 WHEN OTHERS THEN
    	v_resp := '';
		v_resp := pxp.f_agrega_clave(v_resp,'mensaje',SQLERRM);
    	v_resp := pxp.f_agrega_clave(v_resp,'codigo_error',SQLSTATE);
  		v_resp := pxp.f_agrega_clave(v_resp,'procedimientos',v_nombre_funcion);
		raise exception '%',v_resp;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;