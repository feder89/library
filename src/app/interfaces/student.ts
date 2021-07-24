import { Class } from './class';

export interface Student {
  id: number;
  nome: string;
  cognome: string;
  classe: number;
  residenza: string;
  mail: string;
  telefono: string;
  classi: Class;
  cod_fiscale: string;
}

