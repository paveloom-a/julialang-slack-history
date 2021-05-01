import { terser } from 'rollup-plugin-terser';
import commonjs from '@rollup/plugin-commonjs';
import css from 'rollup-plugin-css-only';
import livereload from 'rollup-plugin-livereload';
import preprocess from 'svelte-preprocess';
import resolve from '@rollup/plugin-node-resolve';
import svelte from 'rollup-plugin-svelte';

const production = !process.env.ROLLUP_WATCH;

function serve() {
	let server;

	function toExit() {
		if (server) server.kill(0);
	}

	return {
		writeBundle() {
			if (server) return;
			server = require('child_process').spawn('npm', ['run', 'serve', '--', '--dev'], {
				stdio: ['ignore', 'inherit', 'inherit'],
				shell: true
			});

			process.on('SIGTERM', toExit);
			process.on('exit', toExit);
		}
	};
}

export default {
  input: 'src/main.js',
  output: {
    format: 'esm',
    file: 'public/build/bundle.js',
  },
  plugins: [
    // Take the CSS out
    css({ output: 'bundle.css' }),

    commonjs(),

    // Development mode
    !production && serve(),
    !production && livereload('public'),

    // Production mode
    production && terser(),

    // Locate and bundle third party modules
    resolve(),

    svelte({
      preprocess: preprocess(),
      compilerOptions: {
        dev: !production,
      },
    }),
  ],
  watch: {
    clearScreen: false,
  },
};
