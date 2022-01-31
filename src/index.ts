import Express from "express";
import postgraphile from "postgraphile";

const app = Express();

app.use(
  postgraphile(
    process.env.DATABASE_URL || "postgres://louislec@localhost:5432/test",
    "publ",
    {
      watchPg: true,
      graphiql: true,
      pgDefaultRole: process.env.DATABASE_VISITOR || "demo_visitor",
      ignoreRBAC: false,
      jwtPgTypeIdentifier: "publ.jwt",
      jwtSecret: "lizyvdcmkagc piaucg aiycg qpsiyf zcvdevq",
      enhanceGraphiql: true,
    }
  )
);

app.listen(8007, () => {
  console.log("listening on http://localhost:8007/graphiql");
});
