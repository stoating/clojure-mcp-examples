(ns mcp.mcp
  (:gen-class))

(defn greet
  "Callable entry point to the application."
  [data]
  (println (str "Hello, " (or (:name data) "World") "!")))

(defn plus-three
  "Adds three to the given number."
  [n]
  (+ n 3))

(defn -main
  "I don't do a whole lot ... yet."
  [& args]
  (greet {:name (first args)})
  (println "Demonstrating plus-three function:")
  (println "plus-three(5) =" (plus-three 5))
  (println "plus-three(42) =" (plus-three 42)))
