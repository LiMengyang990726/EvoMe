void translateImportStmt(struct ast *);
void translateFrom(struct ast *);
vector<string> translateMultipleVersionType1Opts(struct ast *a, vector<string>& initial) ;
void translateRange(struct ast *);
void translateWhere(struct ast *);
void translateSelect(struct ast *);
void translateCall(struct ast *);
void translateComparison(struct ast *);
void eval(struct ast *);