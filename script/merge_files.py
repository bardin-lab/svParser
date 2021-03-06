import os, sys
import fnmatch
import pandas as pd
import ntpath
from optparse import OptionParser


def merge_samples(options):
    if not options.directory:
        options.directory = os.getcwd()

    out_file = os.path.join(options.directory, options.out_file)

    print("Writing '%s'" % out_file)

    options.extension = "*" + options.extension
    print(fnmatch.filter(os.listdir(options.directory), options.extension))
    files = fnmatch.filter(os.listdir(options.directory), options.extension)
    # header = list(pd.read_csv(os.path.join(options.directory, files[0]), delimiter="\t", nrows=1).columns)
    header = ['sample', 'event', 'source', 'type', 'chromosome1', 'bp1', 'chromosome2', 'bp2', 'split_reads',
                         'disc_reads', 'genotype', 'id', 'length(Kb)', 'position', 'configuration', 'allele_frequency',
                         'log2(cnv)', 'microhomology', 'inserted_seq', 'consensus', 'contig_sequence', 'mechanism',
                         'bp1_locus', 'bp2_locus', 'affected_genes', 'status', 'notes', 'snp_freq']
    # header.insert(0, 'sample')

    with open(out_file, 'w') as all_out:
        all_out.write('\t'.join(header) + '\n')
        for f in sorted(files):
            print(os.path.join(options.directory, f))
            sample = ntpath.basename(f).split("_")[0]
            df = pd.read_csv(os.path.join(options.directory, f), delimiter="\t", index_col=False, na_filter=False)

            if 'inserted_seq' not in df:
                df['inserted_seq'] = '-'
                df['contig_sequence'] = '-'

            df['sample'] = sample

            # df = df[new_order]
            df = df.reindex(columns=header)
            # df = df.drop([0])
            # df.to_csv(all_out, sep="\t", index=False)

            false_calls = ['F', 'aF']
            if options.normal:
                false_calls = ['F']

            for idx, row in df.iterrows():
                if row['status'] not in false_calls:
                    all_out.write('\t'.join(map(str, row)) + '\n')


def get_args():
    parser = OptionParser()

    parser.add_option("-e", "--extension", dest="extension", action="store", help="extension to merge on")
    parser.add_option("-d", "--directory", dest="directory", action="store", help="Directory to write output to " + "[Default: '.']")
    parser.add_option("-o", "--out_file", dest="out_file", action="store", help="File to write annotated variants to")
    parser.add_option("-n", "--normal", dest="normal", action="store_true", help="This is a normal tissue")

    parser.set_defaults(out_file='all_samples.txt')

    options, args = parser.parse_args()

    if not options.extension:
        parser.print_help()
        print
        sys.exit("[!] Provide an extension to merge on [e.g. '_reannotated_SVs.txt'] Exiting.")
    else:
        return options, args


def main():
    options, args = get_args()

    try:
        merge_samples(options)
    except IOError as err:
        sys.stderr.write("IOError " + str(err) + "\n")
        return


if __name__ == "__main__":
    sys.exit(main())
