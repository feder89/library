import { Class } from './class';
import { Book } from './book';

export interface BookClassAssociation {
  id: number;
  idLibro: number;
  idClasse: number;
  classi: Class;
  libri: Book;
}
