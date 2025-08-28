(ns mcp.mcp
  (:gen-class))

(defn greet
  "Callable entry point to the application."
  [data]
  (println (str "Hello, " (or (:name data) "World") "!")))

(defn plus-two
  "Adds two to the given number."
  [n]
  (+ n 2))

(defn -main
  "I don't do a whole lot ... yet."
  [& args]
  (greet {:name (first args)})
  (println "Demonstrating plus-two function:")
  (println "plus-two(5) =" (plus-two 5))
  (println "plus-two(42) =" (plus-two 42)))
