package org.jamruby.core;

import java.io.File;
import java.io.IOException;

import org.jamruby.exception.ParseException;
import org.jamruby.mruby.AstNode;
import org.jamruby.mruby.MRuby;
import org.jamruby.mruby.ParserState;
import org.jamruby.mruby.Pointer;
import org.jamruby.mruby.Pool;
import org.jamruby.mruby.RObject;
import org.jamruby.mruby.State;
import org.jamruby.mruby.Value;


public class Jamruby {
	private State state;
	
	public static final long UNAVAILABLE_NATIVE_OBJECT = Pointer.NATIVE_NULL_POINTER;
	
	public Jamruby() {
		state = MRuby.open();
	}
	
	public void close() {
		if (null != state) {
			state.close();
			state = null;
		}
	}
	
	public State state() {
		return state;
	}
	
	@Override
	protected void finalize() throws Throwable {
		try {
			super.finalize();
		} finally {
			close();
		}
	}
    
  public Value loadString(String code) {
		return MRuby.loadString(state, code);
	}
}
	
/*	
	public Value run(String command, String...args) {
		final int n = generateCode(MRuby.parse(state, command));
		return run(n, args);
	}
	
	public Value run(File f, String...args) throws IOException {
		final int n = generateCode(MRuby.parse(state, f));
		return run(n, args);
	}
	
	public Value run(ParserState p, String...args) {
		int n= generateCode(p);
		return run(n, args);
	}
	
	public ParserState parse(String command) {
		return validateParserState(MRuby.parse(state, command));
	}
	
	public ParserState parse(File f) throws IOException {
		return validateParserState(MRuby.parse(state, f));
	}
	
	private synchronized ParserState validateParserState(ParserState p) {
		if (null == p) {
			throw new ParseException();
		}
		final AstNode node = p.tree();
		if (!node.available() || 0 != p.nerr()) {
			throw new ParseException();
		}
		return p;
	}
	
	private int generateCode(ParserState p) {
		validateParserState(p);
		final int n = MRuby.generateCode(state, p);
		final Pool pool = p.pool();
		pool.close();
		return n;
	}
	
	private Value run(int n, String...args) {
		final Value ARGV = MRuby.arrayNew(state);
		final int argc = args.length;
		for(int i = 0; i < argc; ++i) {
			MRuby.arrayPush(state, ARGV, MRuby.strNew(state, args[i]));
		}
		MRuby.defineGlobalConst(state, "ARGV", ARGV);
		final Value ret = MRuby.run(state, MRuby.procNew(state, state.irep()[n]), MRuby.topSelf(state));
		final RObject exc = state.exc();
		if (exc.available()) {
			MRuby.p(state, new Value(exc));
		}
		return ret;
	}
}
*/

