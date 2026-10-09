// Практические примеры лекции №7, слайды 12–18, синтаксис Neo4j 5.
// Удаляются исключительно узлы примеров с меткой LectureDemo.
MATCH (n:LectureDemo) DETACH DELETE n;
CREATE (n:LectureDemo:Person {name:'Mike'}) RETURN n.name AS created;
CREATE (:LectureDemo:Person {name:'Anna'}),(:LectureDemo:Person {name:'Alex'}),
 (:LectureDemo:Movie {title:'Matrix'}),(:LectureDemo:Movie {title:'The Terminator'});
MATCH (n:LectureDemo) RETURN labels(n) AS labels,properties(n) AS attributes LIMIT 25;
MATCH (a:LectureDemo:Person {name:'Mike'}),(b:LectureDemo:Person {name:'Anna'})
 MERGE (a)-[:MARRIED]->(b);
MATCH (a:LectureDemo:Person {name:'Mike'}),(b:LectureDemo:Person {name:'Alex'})
 MERGE (a)-[:FRIENDS]->(b);
MATCH (a:LectureDemo:Person {name:'Alex'}),(b:LectureDemo:Movie {title:'The Terminator'})
 MERGE (a)-[:FAVORITE]->(b);
MATCH (a:LectureDemo)-[r]->(b:LectureDemo)
 RETURN coalesce(a.name,a.title) AS source,type(r) AS relation,coalesce(b.name,b.title) AS target;

// В лекции для следующих запросов использован словарь, но сам набор не приложен.
// Минимальный учебный набор слов позволяет выполнить те же операции.
CREATE (a:LectureDemo:Word {name:'бежать'}),(b:LectureDemo:Word {name:'двигаться'}),
 (c:LectureDemo:Word {name:'парить'}),(d:LectureDemo:Word {name:'прямой'}),
 (e:LectureDemo:Word {name:'форма'}),(f:LectureDemo:Word {name:'толстый'}),
 (g:LectureDemo:Word {name:'воровать'}),(h:LectureDemo:Word {name:'профессия'}),
 (:LectureDemo:Word {name:'изолированный пример'}),
 (a)-[:HYPERONYMY]->(b),(c)-[:HYPERONYMY]->(b),
 (d)-[:HYPERONYMY]->(e),(f)-[:HYPERONYMY]->(e),(g)-[:RELATED_TO]->(h);
// START заменён на MATCH; поиск выполняется по полученному elementId.
MATCH (n:LectureDemo {name:'Mike'}) WITH elementId(n) AS wanted
 MATCH (found:LectureDemo) WHERE elementId(found)=wanted RETURN found.name,elementId(found);
MATCH (n:LectureDemo) WHERE n.name IN ['Mike','Anna'] RETURN n.name,elementId(n);
MATCH (n:LectureDemo) WHERE n.name='профессия' RETURN n.name;
// HAS(n.name) заменён на IS NOT NULL.
MATCH (n:LectureDemo) WHERE n.name IS NOT NULL RETURN n.name ORDER BY n.name;
MATCH (n:LectureDemo) WHERE EXISTS {(n)-[:HYPERONYMY]->()} RETURN n.name;
MATCH (n:LectureDemo) RETURN count(n) AS lecture_nodes;
MATCH (:LectureDemo)-[r]->(:LectureDemo) RETURN count(r) AS lecture_relationships;
MATCH (n:LectureDemo {name:'воровать'})--(a) RETURN n.name,a.name;
MATCH (n:LectureDemo) WHERE NOT (n)--() RETURN coalesce(n.name,n.title) AS isolated;
MATCH (n:LectureDemo) WHERE NOT (n)--() DELETE n;
MATCH (n:LectureDemo) WHERE NOT (n)--() RETURN count(n) AS isolated_after_delete;
MATCH (a:LectureDemo {name:'бежать'}),(b:LectureDemo {name:'парить'}),
 p=shortestPath((a)-[*..5]-(b)) RETURN [n IN nodes(p)|n.name] AS shortest_path;
MATCH (a:LectureDemo {name:'прямой'}),(b:LectureDemo {name:'толстый'}),
 p=allShortestPaths((a)-[:SYNONYMY|HYPERONYMY*..5]-(b))
 RETURN [n IN nodes(p)|n.name] AS typed_shortest_paths;
// id() оставлен только для демонстрации последнего примера старой лекции.
MATCH (n:LectureDemo) RETURN n.name,id(n) AS internal_id ORDER BY internal_id DESC LIMIT 1;
MATCH (n:LectureDemo) DETACH DELETE n;
MATCH (n:LectureDemo) RETURN count(n) AS lecture_nodes_after_cleanup;
