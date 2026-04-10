<script lang="ts">
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import packageIndex from '$lib/generated/package-index.json';

	type PackageEntry = {
		pkgbase: string;
		pkgnames: string[];
		pkgdesc: string;
		pkgver: string;
		pkgrel: string;
		version: string;
		arch: string[];
		depends: string[];
		makedepends: string[];
		checkdepends: string[];
		url: string;
		sourceUrl: string;
		upstreamRef: string;
		upstreamPrefix: string;
		packagePath: string;
		searchText: string;
	};

	type PackageIndex = {
		packageCount: number;
		architectures: string[];
		packages: PackageEntry[];
	};

	const index = packageIndex as PackageIndex;
	const packages = index.packages;

	let query = $state('');

	const normalizedQuery = $derived(query.trim().toLowerCase());

	const filteredPackages = $derived.by(() => {
		if (!normalizedQuery) {
			return packages;
		}

		return packages.filter((pkg) => pkg.searchText.includes(normalizedQuery));
	});

	function resetQuery() {
		query = '';
	}

	function joinValues(values: string[]) {
		return values.length > 0 ? values.join(', ') : 'none';
	}
</script>

<svelte:head>
	<title>k3apps</title>
	<meta
		name="description"
		content="Static package search for the k3apps custom Arch Linux repository."
	/>
</svelte:head>

<main class="mx-auto flex min-h-screen w-full max-w-6xl flex-col gap-4 px-4 py-6 md:px-6 md:py-8">
	<section class="brutal-box gap-5 p-5 md:gap-8 md:p-8">
		<div class="flex flex-col gap-6 md:flex-row md:items-end md:justify-between">
			<div class="space-y-3">
				<p class="mono-label">Static Package Index</p>
				<h1 class="text-5xl font-semibold uppercase tracking-[-0.1em] md:text-7xl">k3apps</h1>
				<p class="max-w-2xl text-sm leading-relaxed text-foreground/78 md:text-base">
					Search the packages published from this repository. The interface is static, the
					results are client-side, and the pacman repo stays under <code>x86_64/</code>.
				</p>
			</div>

			<div class="grid grid-cols-3 gap-2 md:w-[22rem]">
				<div class="stat-box">
					<p class="mono-label">Packages</p>
					<p class="mt-2 text-2xl font-semibold tracking-[-0.06em]">{index.packageCount}</p>
				</div>
				<div class="stat-box">
					<p class="mono-label">Shown</p>
					<p class="mt-2 text-2xl font-semibold tracking-[-0.06em]">{filteredPackages.length}</p>
				</div>
				<div class="stat-box">
					<p class="mono-label">Arch</p>
					<p class="mt-2 text-2xl font-semibold tracking-[-0.06em]">{index.architectures.length}</p>
				</div>
			</div>
		</div>

		<div class="border-2 border-border bg-background/80 p-3">
			<div class="flex flex-col gap-3 md:flex-row">
				<Input
					bind:value={query}
					type="search"
					placeholder={packages.length > 0
						? 'Search pkgbase, pkgname, description, dependency'
						: 'No packages indexed yet'}
					class="h-12 border-2 border-border bg-background px-4 text-base text-foreground placeholder:text-foreground/36 focus-visible:border-foreground focus-visible:ring-0"
				/>

				{#if query}
					<Button
						variant="outline"
						class="h-12 border-2 border-border bg-background px-4 font-semibold uppercase tracking-[0.22em] text-foreground shadow-none hover:bg-foreground hover:text-background focus-visible:ring-0"
						onclick={resetQuery}
					>
						Clear
					</Button>
				{/if}
			</div>

			<p class="mono-label mt-3">
				Searches pkgbase, package names, descriptions, dependencies, and upstream URLs.
			</p>
		</div>
	</section>

	<section class="grid gap-3">
		{#if packages.length === 0}
			<div class="result-box">
				<p class="mono-label">Empty Repo</p>
				<h2 class="mt-3 text-2xl font-semibold uppercase tracking-[-0.08em]">No Packages Yet</h2>
				<p class="mt-3 max-w-2xl text-sm leading-relaxed text-foreground/78 md:text-base">
					Add a package under <code>packages/&lt;pkgbase&gt;/</code>, generate its
					<code>.SRCINFO</code>, and rebuild the site to have it indexed here.
				</p>
			</div>
		{:else if filteredPackages.length === 0}
			<div class="result-box">
				<p class="mono-label">No Match</p>
				<h2 class="mt-3 text-2xl font-semibold uppercase tracking-[-0.08em]">Nothing Found</h2>
				<p class="mt-3 max-w-2xl text-sm leading-relaxed text-foreground/78 md:text-base">
					No indexed package matches <code>{query}</code>.
				</p>
			</div>
		{:else}
			{#each filteredPackages as pkg (pkg.pkgbase)}
				<article class="result-box">
					<div class="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
						<div class="space-y-3">
							<div class="flex flex-wrap items-baseline gap-3">
								<h2 class="text-2xl font-semibold uppercase tracking-[-0.08em] md:text-3xl">
									{pkg.pkgbase}
								</h2>
								<p class="mono-label">v {pkg.version || 'unversioned'}</p>
							</div>

							{#if pkg.pkgdesc}
								<p class="max-w-3xl text-sm leading-relaxed text-foreground/78 md:text-base">
									{pkg.pkgdesc}
								</p>
							{/if}
						</div>

						<div class="flex flex-wrap gap-2">
							{#each pkg.arch as architecture}
								<span class="tag-box">{architecture}</span>
							{/each}
						</div>
					</div>

					<div class="mt-4 grid gap-2 md:grid-cols-2 xl:grid-cols-4">
						<div class="meta-box">
							<p class="mono-label">Pkgname</p>
							<p class="mt-2 text-sm leading-relaxed text-foreground/84">{joinValues(pkg.pkgnames)}</p>
						</div>
						<div class="meta-box">
							<p class="mono-label">Depends</p>
							<p class="mt-2 text-sm leading-relaxed text-foreground/84">{joinValues(pkg.depends)}</p>
						</div>
						<div class="meta-box">
							<p class="mono-label">Make Depends</p>
							<p class="mt-2 text-sm leading-relaxed text-foreground/84">
								{joinValues(pkg.makedepends)}
							</p>
						</div>
						<div class="meta-box">
							<p class="mono-label">Path</p>
							<p class="mt-2 text-sm leading-relaxed text-foreground/84">{pkg.packagePath}</p>
						</div>
					</div>

					{#if pkg.url || pkg.sourceUrl}
						<div class="mt-4 flex flex-wrap gap-3 text-sm text-foreground/78">
							{#if pkg.url}
								<a
									class="border border-border px-3 py-2 underline-offset-4 transition-colors hover:bg-foreground hover:text-background"
									href={pkg.url}
									rel="noreferrer"
									target="_blank"
								>
									homepage
								</a>
							{/if}

							{#if pkg.sourceUrl}
								<a
									class="border border-border px-3 py-2 underline-offset-4 transition-colors hover:bg-foreground hover:text-background"
									href={pkg.sourceUrl}
									rel="noreferrer"
									target="_blank"
								>
									upstream
								</a>
							{/if}
						</div>
					{/if}
				</article>
			{/each}
		{/if}
	</section>
</main>
