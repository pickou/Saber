package uk.ac.imperial.lsds.saber.cql.expressions.ints;

import uk.ac.imperial.lsds.saber.ITupleSchema;
import uk.ac.imperial.lsds.saber.buffers.IQueryBuffer;
import uk.ac.imperial.lsds.saber.cql.expressions.Expression;

public interface IntExpression extends Expression {
	
	public int eval(IQueryBuffer buffer, ITupleSchema schema, int offset);
}
