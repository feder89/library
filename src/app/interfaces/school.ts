export interface School {
  id: number;
  nome: string;
  tipologia: SchoolType;
}

export enum SchoolType {
  Elementare = 'Elementare',
  Media = 'Media',
  Superiore = 'Superiore'
}
