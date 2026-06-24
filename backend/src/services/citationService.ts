import { Paper } from "./evidenceService";

export interface Citation {
  apa: string;
  mla: string;
  ieee: string;
}

export interface CitationResult {
  [paperId: string]: Citation;
}

interface ParsedAuthor {
  lastName: string;
  firstName: string;
  initials: string;
}

export class CitationService {
  
  async generateCitations(papers: Paper[]): Promise<CitationResult> {
    const result: CitationResult = {};

    papers.forEach((paper) => {
      const authors = paper.authors || [];
      const parsedAuthors = authors.map(name => this.parseAuthorName(name));

      result[paper.id] = {
        apa: this.formatAPA(paper, parsedAuthors),
        mla: this.formatMLA(paper, parsedAuthors),
        ieee: this.formatIEEE(paper, parsedAuthors)
      };
    });

    return result;
  }

  // Fungsi memecah nama lengkap menjadi Last Name, First Name, dan Inisial
  private parseAuthorName(name: string): ParsedAuthor {
    const cleanName = name.replace(/\s+/g, ' ').trim();
    const parts = cleanName.split(' ');
    
    // Jika nama hanya 1 kata
    if (parts.length === 1) {
      return {
        lastName: parts[0],
        firstName: '',
        initials: parts[0].charAt(0).toUpperCase() + '.'
      };
    }

    const lastName = parts[parts.length - 1]; // Kata terakhir dianggap Last Name
    const firstName = parts[0];
    const middleNames = parts.slice(1, parts.length - 1);
    
    const initials = [firstName, ...middleNames]
      .map(n => n.charAt(0).toUpperCase() + '.')
      .join(' ');

    return {
      lastName,
      firstName: [firstName, ...middleNames].join(' '),
      initials
    };
  }

  // Format APA: LastName, F. M. (Year). Title. https://doi.org/xxx
  private formatAPA(paper: Paper, authors: ParsedAuthor[]): string {
    let authorText = "Unknown Author";

    if (authors.length === 1) {
      authorText = `${authors[0].lastName}, ${authors[0].initials}`;
    } else if (authors.length === 2) {
      authorText = `${authors[0].lastName}, ${authors[0].initials}, & ${authors[1].lastName}, ${authors[1].initials}`;
    } else if (authors.length > 2) {
      authorText = `${authors[0].lastName}, ${authors[0].initials}, et al.`;
    }

    const doiText = paper.doi ? ` ${paper.doi}` : '';
    return `${authorText} (${paper.year}). ${paper.title}.${doiText}`;
  }

  // Format MLA: LastName, FirstName, et al. "Title." Year.
  private formatMLA(paper: Paper, authors: ParsedAuthor[]): string {
    let authorText = "Unknown Author";

    if (authors.length === 1) {
      authorText = `${authors[0].lastName}, ${authors[0].firstName}`;
    } else if (authors.length === 2) {
      authorText = `${authors[0].lastName}, ${authors[0].firstName}, and ${authors[1].firstName} ${authors[1].lastName}`;
    } else if (authors.length > 2) {
      authorText = `${authors[0].lastName}, ${authors[0].firstName}, et al.`;
    }

    return `${authorText}. "${paper.title}." ${paper.year}.`;
  }

  // Format IEEE: [Ref] F. M. LastName and S. S. LastName, "Title," Year.
  private formatIEEE(paper: Paper, authors: ParsedAuthor[]): string {
    let authorText = "Unknown Author";

    if (authors.length === 1) {
      authorText = `${authors[0].initials} ${authors[0].lastName}`;
    } else if (authors.length === 2) {
      authorText = `${authors[0].initials} ${authors[0].lastName} and ${authors[1].initials} ${authors[1].lastName}`;
    } else if (authors.length > 2) {
      authorText = `${authors[0].initials} ${authors[0].lastName} et al.`;
    }

    return `${authorText}, "${paper.title}," ${paper.year}.`;
  }
}
