import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptPath = fileURLToPath(import.meta.url);
const scriptDir = path.dirname(scriptPath);
const repoRoot = path.resolve(scriptDir, '..', '..');
const packagesRoot = path.join(repoRoot, 'packages');
const outputPath = path.join(scriptDir, '..', 'src', 'lib', 'generated', 'package-index.json');

function pushUnique(values, value) {
	if (!value || values.includes(value)) {
		return;
	}

	values.push(value);
}

function normalizeValue(rawValue) {
	const value = rawValue.trim();

	if (
		(value.startsWith('"') && value.endsWith('"')) ||
		(value.startsWith("'") && value.endsWith("'"))
	) {
		return value.slice(1, -1);
	}

	return value;
}

function sortValues(values) {
	return [...values].sort((left, right) => left.localeCompare(right));
}

function parseSrcinfo(content, fallbackPkgbase) {
	const record = {
		pkgbase: fallbackPkgbase,
		pkgnames: [],
		pkgdesc: '',
		pkgver: '',
		pkgrel: '',
		arch: [],
		depends: [],
		makedepends: [],
		checkdepends: [],
		url: ''
	};

	for (const rawLine of content.split(/\r?\n/)) {
		const line = rawLine.trim();

		if (!line || line.startsWith('#')) {
			continue;
		}

		const separatorIndex = line.indexOf('=');
		if (separatorIndex === -1) {
			continue;
		}

		const key = line.slice(0, separatorIndex).trim();
		const value = line.slice(separatorIndex + 1).trim();

		switch (key) {
			case 'pkgbase':
				record.pkgbase = value || fallbackPkgbase;
				break;
			case 'pkgname':
				pushUnique(record.pkgnames, value);
				break;
			case 'pkgdesc':
				if (!record.pkgdesc && value) {
					record.pkgdesc = value;
				}
				break;
			case 'pkgver':
				if (!record.pkgver && value) {
					record.pkgver = value;
				}
				break;
			case 'pkgrel':
				if (!record.pkgrel && value) {
					record.pkgrel = value;
				}
				break;
			case 'arch':
				pushUnique(record.arch, value);
				break;
			case 'depends':
				pushUnique(record.depends, value);
				break;
			case 'makedepends':
				pushUnique(record.makedepends, value);
				break;
			case 'checkdepends':
				pushUnique(record.checkdepends, value);
				break;
			case 'url':
				if (!record.url && value) {
					record.url = value;
				}
				break;
			default:
				break;
		}
	}

	record.pkgnames = sortValues(record.pkgnames);
	record.arch = sortValues(record.arch);
	record.depends = sortValues(record.depends);
	record.makedepends = sortValues(record.makedepends);
	record.checkdepends = sortValues(record.checkdepends);

	return record;
}

function parseSourceConfig(content) {
	const data = {};

	for (const rawLine of content.split(/\r?\n/)) {
		const line = rawLine.trim();

		if (!line || line.startsWith('#')) {
			continue;
		}

		const match = line.match(/^([A-Z0-9_]+)=(.*)$/);
		if (!match) {
			continue;
		}

		data[match[1]] = normalizeValue(match[2]);
	}

	return data;
}

function buildSearchText(pkg) {
	return [
		pkg.pkgbase,
		pkg.pkgdesc,
		pkg.version,
		...pkg.pkgnames,
		...pkg.arch,
		...pkg.depends,
		...pkg.makedepends,
		...pkg.checkdepends,
		pkg.url,
		pkg.sourceUrl,
		pkg.packagePath
	]
		.filter(Boolean)
		.join(' ')
		.toLowerCase();
}

async function readPackages() {
	try {
		const entries = await fs.readdir(packagesRoot, { withFileTypes: true });
		return entries
			.filter((entry) => entry.isDirectory())
			.map((entry) => entry.name)
			.sort((left, right) => left.localeCompare(right));
	} catch (error) {
		if (error && typeof error === 'object' && 'code' in error && error.code === 'ENOENT') {
			return [];
		}

		throw error;
	}
}

async function buildIndex() {
	const packageBases = await readPackages();
	const packages = [];

	for (const pkgbase of packageBases) {
		const packageDir = path.join(packagesRoot, pkgbase);
		const srcinfoPath = path.join(packageDir, '.SRCINFO');
		const sourceConfigPath = path.join(packageDir, 'source.conf');

		let srcinfoContent;
		try {
			srcinfoContent = await fs.readFile(srcinfoPath, 'utf8');
		} catch (error) {
			if (error && typeof error === 'object' && 'code' in error && error.code === 'ENOENT') {
				throw new Error(`package '${pkgbase}' is missing .SRCINFO`);
			}

			throw error;
		}

		const srcinfo = parseSrcinfo(srcinfoContent, pkgbase);
		let sourceConfig = {};

		try {
			sourceConfig = parseSourceConfig(await fs.readFile(sourceConfigPath, 'utf8'));
		} catch (error) {
			if (!(error && typeof error === 'object' && 'code' in error && error.code === 'ENOENT')) {
				throw error;
			}
		}

		const pkg = {
			pkgbase: srcinfo.pkgbase,
			pkgnames: srcinfo.pkgnames,
			pkgdesc: srcinfo.pkgdesc,
			pkgver: srcinfo.pkgver,
			pkgrel: srcinfo.pkgrel,
			version: [srcinfo.pkgver, srcinfo.pkgrel].filter(Boolean).join('-'),
			arch: srcinfo.arch,
			depends: srcinfo.depends,
			makedepends: srcinfo.makedepends,
			checkdepends: srcinfo.checkdepends,
			url: srcinfo.url,
			sourceUrl: sourceConfig.UPSTREAM_URL ?? '',
			upstreamRef: sourceConfig.UPSTREAM_REF ?? '',
			upstreamPrefix: sourceConfig.UPSTREAM_PREFIX ?? `packages/${pkgbase}/upstream`,
			packagePath: `packages/${pkgbase}`,
			searchText: ''
		};

		pkg.searchText = buildSearchText(pkg);
		packages.push(pkg);
	}

	const architectures = sortValues([...new Set(packages.flatMap((pkg) => pkg.arch))]);

	return {
		packageCount: packages.length,
		architectures,
		packages
	};
}

try {
	const packageIndex = await buildIndex();
	await fs.mkdir(path.dirname(outputPath), { recursive: true });
	await fs.writeFile(outputPath, `${JSON.stringify(packageIndex, null, 2)}\n`);
} catch (error) {
	console.error(error instanceof Error ? error.message : error);
	process.exit(1);
}
