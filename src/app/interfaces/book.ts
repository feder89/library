import { Publisher } from './publisher';

export interface Book {
  id: number;
  casa_editrice: number;
  titolo: string;
  prezzo: number;
  codice_isbn: string;
  case_editrici: Publisher;
  tomi: number;
  materia: string;
}
