import Express from "express";
import postgraphile from "postgraphile";

const app = Express();

app.use(
  postgraphile("postgres://louislec@localhost:5432/test", "publ", {
    watchPg: true,
    graphiql: true,
    pgDefaultRole: "demo_visitor",
    ignoreRBAC: true,
    jwtPgTypeIdentifier: "publ.jwt",
    jwtSecret: "lizyvdcmkagc piaucg aiycg qpsiyf zcvdevq",
    enhanceGraphiql: true,
  })
);

app.listen(8007, () => {
  console.log("listening on http://localhost:8007/graphiql");
});
